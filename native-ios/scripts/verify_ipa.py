#!/usr/bin/env python3
"""Verify a PROJECT 100M iPhoneOS IPA without trusting the build log.

Portable (Python 3 standard library only): parses the ZIP, Info.plist and the
main Mach-O executable directly, including the code-signature super-blob, so
the same checks run on the macOS CI runner and on Windows/Linux for review.

Exit status is non-zero when any required check fails. A JSON report is
written with --report. This proves package structure, platform and declared
entitlements only; it does NOT prove the IPA is installable or signed by Apple.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import struct
import sys
import zipfile

APP = "Payload/PROJECT100M.app/"
EXPECTED_BUNDLE_ID = "com.project100m.ios"
EXPECTED_MIN_OS = "17.0"
REQUIRED_INFO_KEYS = (
    "CFBundleIdentifier", "CFBundleExecutable", "CFBundleShortVersionString", "CFBundleVersion",
    "MinimumOSVersion", "NSHealthShareUsageDescription", "UIRequiredDeviceCapabilities",
)

MH_MAGIC_64 = 0xFEEDFACF
FAT_MAGIC = 0xCAFEBABE
CPU_TYPE_ARM64 = 0x0100000C
LC_CODE_SIGNATURE = 0x1D
LC_ENCRYPTION_INFO_64 = 0x2C
LC_VERSION_MIN_IPHONEOS = 0x25
LC_BUILD_VERSION = 0x32
PLATFORMS = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 6: "macCatalyst", 7: "iOSSimulator"}
CSMAGIC_EMBEDDED_SIGNATURE = 0xFADE0CC0
CSMAGIC_EMBEDDED_ENTITLEMENTS = 0xFADE7171
CSMAGIC_CODEDIRECTORY = 0xFADE0C02
CSMAGIC_BLOBWRAPPER = 0xFADE0B01
CS_ADHOC = 0x2


def _slices(data: bytes):
    magic = struct.unpack_from(">I", data, 0)[0]
    if magic == FAT_MAGIC:
        count = struct.unpack_from(">I", data, 4)[0]
        for i in range(count):
            cpu, _sub, offset, size, _align = struct.unpack_from(">iiIII", data, 8 + i * 20)
            yield cpu & 0xFFFFFFFF, data[offset:offset + size]
    else:
        yield struct.unpack_from("<i", data, 4)[0] & 0xFFFFFFFF, data


def parse_macho(data: bytes) -> dict:
    """Return architecture, platform, minimum OS and signature details of a Mach-O."""
    out = {"slices": []}
    for cpu, blob in _slices(data):
        info = {"cpu": "arm64" if cpu == CPU_TYPE_ARM64 else hex(cpu), "platform": None,
                "minos": None, "signature": "none", "entitlements": None, "encrypted": False}
        if struct.unpack_from("<I", blob, 0)[0] != MH_MAGIC_64:
            info["error"] = "not a 64-bit little-endian Mach-O"
            out["slices"].append(info)
            continue
        ncmds = struct.unpack_from("<I", blob, 16)[0]
        offset = 32
        for _ in range(ncmds):
            cmd, size = struct.unpack_from("<II", blob, offset)
            if cmd == LC_BUILD_VERSION:
                platform, minos = struct.unpack_from("<II", blob, offset + 8)
                info["platform"] = PLATFORMS.get(platform, str(platform))
                info["minos"] = f"{minos >> 16}.{(minos >> 8) & 0xFF}"
            elif cmd == LC_VERSION_MIN_IPHONEOS and info["platform"] is None:
                version = struct.unpack_from("<I", blob, offset + 8)[0]
                info["platform"] = "iOS"
                info["minos"] = f"{version >> 16}.{(version >> 8) & 0xFF}"
            elif cmd == LC_ENCRYPTION_INFO_64:
                info["encrypted"] = struct.unpack_from("<I", blob, offset + 16)[0] != 0
            elif cmd == LC_CODE_SIGNATURE:
                dataoff, datasize = struct.unpack_from("<II", blob, offset + 8)
                info.update(_parse_signature(blob[dataoff:dataoff + datasize]))
            offset += size
        out["slices"].append(info)
    return out


def _parse_signature(sig: bytes) -> dict:
    result = {"signature": "unrecognised", "entitlements": None, "cms": False}
    if len(sig) < 12 or struct.unpack_from(">I", sig, 0)[0] != CSMAGIC_EMBEDDED_SIGNATURE:
        return result
    count = struct.unpack_from(">I", sig, 8)[0]
    flags = None
    for i in range(count):
        _slot, off = struct.unpack_from(">II", sig, 12 + i * 8)
        magic, length = struct.unpack_from(">II", sig, off)
        if magic == CSMAGIC_EMBEDDED_ENTITLEMENTS:
            result["entitlements"] = plistlib.loads(sig[off + 8:off + length])
        elif magic == CSMAGIC_CODEDIRECTORY and flags is None:
            flags = struct.unpack_from(">I", sig, off + 12)[0]
        elif magic == CSMAGIC_BLOBWRAPPER and length > 8:
            result["cms"] = True
    if flags is not None:
        result["signature"] = "adhoc" if flags & CS_ADHOC else "certificate"
    return result


def verify(path: str, expect_entitlement: str | None = "com.apple.developer.healthkit") -> dict:
    checks: list[dict] = []

    def check(name: str, ok: bool, detail) -> None:
        checks.append({"check": name, "passed": bool(ok), "detail": detail})

    with open(path, "rb") as handle:
        raw = handle.read()
    report = {"ipa": path, "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw), "checks": checks}
    try:
        archive = zipfile.ZipFile(path)
    except zipfile.BadZipFile as error:
        check("zip-structure", False, str(error))
        return report
    names = archive.namelist()
    bad = archive.testzip()
    check("zip-structure", bad is None, f"{len(names)} entries" if bad is None else f"corrupt member {bad}")
    top = sorted({n.split("/", 1)[0] for n in names})
    check("payload-root", top == ["Payload"], top)
    check("payload-app", any(n.startswith(APP) for n in names), APP)
    if f"{APP}Info.plist" not in names:
        check("info-plist", False, "missing")
        return report
    info = plistlib.loads(archive.read(f"{APP}Info.plist"))
    missing = [k for k in REQUIRED_INFO_KEYS if not info.get(k)]
    check("info-required-keys", not missing, missing or "all present")
    check("bundle-identifier", info.get("CFBundleIdentifier") == EXPECTED_BUNDLE_ID, info.get("CFBundleIdentifier"))
    check("minimum-os", info.get("MinimumOSVersion") == EXPECTED_MIN_OS, info.get("MinimumOSVersion"))
    check("supported-platform", info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], info.get("CFBundleSupportedPlatforms"))
    check("dt-platform", info.get("DTPlatformName") == "iphoneos", info.get("DTPlatformName"))
    check("not-simulator-sdk", "simulator" not in str(info.get("DTSDKName", "")).lower(), info.get("DTSDKName"))
    report["info"] = {k: info.get(k) for k in (
        "CFBundleIdentifier", "CFBundleDisplayName", "CFBundleShortVersionString", "CFBundleVersion",
        "MinimumOSVersion", "DTPlatformName", "DTSDKName", "DTXcode", "DTXcodeBuild", "UIRequiredDeviceCapabilities")}
    check("no-embedded-provisioning-profile", f"{APP}embedded.mobileprovision" not in names,
          "unsigned build carries no Apple provisioning profile")
    executable = f"{APP}{info.get('CFBundleExecutable', '')}"
    if executable not in names:
        check("main-executable", False, f"missing {executable}")
        return report
    macho = parse_macho(archive.read(executable))
    report["macho"] = macho
    slices = macho["slices"]
    check("architecture-arm64", [s["cpu"] for s in slices] == ["arm64"], [s["cpu"] for s in slices])
    check("platform-iphoneos", all(s["platform"] == "iOS" for s in slices), [s["platform"] for s in slices])
    check("binary-minos", all(s["minos"] == EXPECTED_MIN_OS for s in slices), [s["minos"] for s in slices])
    check("not-encrypted", not any(s["encrypted"] for s in slices), "FairPlay cryptid 0")
    states = [s["signature"] for s in slices]
    check("no-apple-certificate-signature", all(s in ("none", "adhoc") for s in states), states)
    if expect_entitlement:
        ents = [s.get("entitlements") or {} for s in slices]
        check("declared-entitlement", all(e.get(expect_entitlement) is True for e in ents),
              {expect_entitlement: [e.get(expect_entitlement) for e in ents]})
    report["passed"] = all(c["passed"] for c in checks)
    return report


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa")
    parser.add_argument("--report")
    parser.add_argument("--no-entitlement-check", action="store_true")
    args = parser.parse_args(argv)
    report = verify(args.ipa, None if args.no_entitlement_check else "com.apple.developer.healthkit")
    report.setdefault("passed", False)
    text = json.dumps(report, indent=2, default=str, ensure_ascii=False)
    if args.report:
        with open(args.report, "w", encoding="utf-8") as handle:
            handle.write(text + "\n")
    for item in report["checks"]:
        print(("PASS " if item["passed"] else "FAIL ") + item["check"] + ": " + json.dumps(item["detail"], default=str, ensure_ascii=False))
    print("SHA256 " + report["sha256"])
    print("RESULT " + ("PASS" if report["passed"] else "FAIL"))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
