import importlib.util
import plistlib
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "verify_ipa", Path(__file__).parents[2] / "native-ios" / "scripts" / "verify_ipa.py")
verify_ipa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify_ipa)


def macho(platform=2, minos=(17, 0), entitlements=None, adhoc=True, cpu=0x0100000C):
    """Build a minimal synthetic arm64 Mach-O with LC_BUILD_VERSION and an optional signature."""
    commands = struct.pack("<IIIIII", 0x32, 24, platform, (minos[0] << 16) | (minos[1] << 8), 0, 0)
    ncmds = 1
    signature = b""
    if entitlements is not None:
        ent = plistlib.dumps(entitlements)
        ent_blob = struct.pack(">II", 0xFADE7171, 8 + len(ent)) + ent
        cd = struct.pack(">IIII", 0xFADE0C02, 44, 0x20400, 0x2 if adhoc else 0) + b"\0" * 28
        header_len = 12 + 2 * 8
        signature = struct.pack(">III", 0xFADE0CC0, header_len + len(cd) + len(ent_blob), 2)
        signature += struct.pack(">II", 0, header_len) + struct.pack(">II", 5, header_len + len(cd))
        signature += cd + ent_blob
        ncmds += 1
    header_size = 32 + len(commands) + (16 if signature else 0)
    if signature:
        commands += struct.pack("<IIII", 0x1D, 16, header_size, len(signature))
    header = struct.pack("<IiiIIIII", 0xFEEDFACF, cpu, 0, 2, ncmds, len(commands), 0, 0)
    return header + commands + signature


def info(**overrides):
    base = {
        "CFBundleIdentifier": "com.project100m.ios", "CFBundleExecutable": "PROJECT100M",
        "CFBundleShortVersionString": "1.0", "CFBundleVersion": "1", "MinimumOSVersion": "17.0",
        "NSHealthShareUsageDescription": "reads", "UIRequiredDeviceCapabilities": ["arm64"],
        "CFBundleSupportedPlatforms": ["iPhoneOS"], "DTPlatformName": "iphoneos", "DTSDKName": "iphoneos18.5",
        "CFBundleIcons": {"CFBundlePrimaryIcon": {"CFBundleIconName": "AppIcon"}},
    }
    base.update(overrides)
    return plistlib.dumps(base, fmt=plistlib.FMT_BINARY)


class VerifyIpaTests(unittest.TestCase):
    def build(self, binary, plist=None, extra=None):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        path = Path(temp.name) / "app.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/PROJECT100M.app/Info.plist", plist or info())
            archive.writestr("Payload/PROJECT100M.app/PROJECT100M", binary)
            for name, data in (extra or {}).items():
                archive.writestr(name, data)
        return verify_ipa.verify(str(path))

    def failed(self, report):
        return {c["check"] for c in report["checks"] if not c["passed"]}

    def test_valid_device_ipa_passes(self):
        report = self.build(macho(entitlements={"com.apple.developer.healthkit": True}))
        self.assertTrue(report["passed"], self.failed(report))
        self.assertEqual(report["macho"]["slices"][0]["signature"], "adhoc")

    def test_simulator_binary_fails(self):
        report = self.build(macho(platform=7, entitlements={"com.apple.developer.healthkit": True}))
        self.assertIn("platform-iphoneos", self.failed(report))

    def test_missing_entitlement_and_wrong_bundle_fail(self):
        report = self.build(macho(entitlements={}), info(CFBundleIdentifier="x.y"))
        self.assertTrue({"declared-entitlement", "bundle-identifier"} <= self.failed(report))

    def test_certificate_signature_and_profile_fail(self):
        report = self.build(macho(entitlements={"com.apple.developer.healthkit": True}, adhoc=False),
                            extra={"Payload/PROJECT100M.app/embedded.mobileprovision": b"x"})
        self.assertTrue({"no-apple-certificate-signature", "no-embedded-provisioning-profile"} <= self.failed(report))

    def test_wrong_architecture_and_root_fail(self):
        report = self.build(macho(cpu=0x01000007, entitlements={"com.apple.developer.healthkit": True}),
                            extra={"stray.txt": b"x"})
        self.assertTrue({"architecture-arm64", "payload-root"} <= self.failed(report))


if __name__ == "__main__":
    unittest.main()
