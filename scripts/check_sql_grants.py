"""Conservative static DDL grant lint; runtime ACL/RLS tests remain mandatory."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check(text):
    # Ignore comments, string literals and function bodies. Dynamic DDL needs manual review.
    text = re.sub(r"/\*.*?\*/|--[^\n]*|'(?:''|[^'])*'|\$([A-Za-z_]*?)\$.*?\$\1\$", " ", text, flags=re.S)
    objects = re.findall(r'\bcreate\s+(?:or\s+replace\s+)?(table|function)\s+(?:if\s+not\s+exists\s+)?([a-z_][\w]*\.[a-z_][\w]*)', text, re.I)
    errors = []
    for kind, name in objects:
        optional_kind = r'(?:table\s+)?' if kind.lower() == 'table' else r'function\s+'
        pattern = r'\bgrant\s+[^;]+?\s+on\s+' + optional_kind + re.escape(name) + r'\b'
        if not re.search(pattern, text, re.I):
            errors.append(f'{kind} {name}: explicit GRANT required (deny-only objects need separate reviewed deployment handling)')
    if re.search(r'\bgrant\s+all(?:\s+privileges)?\s+[^;]+?\bto\s+[^;]*\b(?:public|anon|authenticated)\b', text, re.I):
        errors.append('GRANT ALL to client roles is forbidden')
    return errors


def main():
    files = [ROOT / 'supabase-schema.sql', *sorted((ROOT / 'supabase/migrations').glob('*.sql')),
             *sorted((ROOT / 'supabase/proposals').glob('*.sql'))]
    errors = [str(path.relative_to(ROOT)) + ': ' + error for path in files for error in check(path.read_text(encoding='utf-8'))]
    print('\n'.join(errors) if errors else f'PASS: explicit-grant lint on {len(files)} SQL files')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
