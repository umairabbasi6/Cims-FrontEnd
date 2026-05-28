#!/usr/bin/env python3
"""Auto-fix Dart `build` method signatures.

Usage:
  python tools/fix_dart_build_signatures.py [--apply] PATH...

By default the script runs in dry-run mode and prints unified diffs of proposed
changes. Use `--apply` to overwrite files.
"""
import argparse
import os
import re
import sys
from difflib import unified_diff


SIGNATURE_RE = re.compile(r"(Widget\s+build\s*\()([^)]*)(\))")


CLASS_DECL_RE = re.compile(r"class\s+(\w+)\s+extends\s+(StatelessWidget|State<[^>]+>)")


def fix_signature(content: str) -> tuple:
    """Broad fix: replace any `Widget build(...)` lacking `BuildContext`.
    Also scan class bodies for `build` inside widget classes and fix there.
    Returns (new_content, changed_flag).
    """
    changed = False

    def repl(m):
        nonlocal changed
        params = m.group(2)
        if 'BuildContext' in params:
            return m.group(0)
        changed = True
        return m.group(1) + 'BuildContext context' + m.group(3)

    # Quick global replace for simple cases
    new = SIGNATURE_RE.sub(repl, content)

    # Now handle class-scoped build methods where simple regex may miss
    for m in CLASS_DECL_RE.finditer(new):
        start = m.end()
        # find opening brace
        brace_idx = new.find('{', start)
        if brace_idx == -1:
            continue
        # extract class body by brace matching
        i = brace_idx
        depth = 0
        end_idx = -1
        while i < len(new):
            if new[i] == '{':
                depth += 1
            elif new[i] == '}':
                depth -= 1
                if depth == 0:
                    end_idx = i
                    break
            i += 1
        if end_idx == -1:
            continue
        class_body = new[brace_idx+1:end_idx]
        # search for build method inside class body
        bm = SIGNATURE_RE.search(class_body)
        if bm:
            params = bm.group(2)
            if 'BuildContext' not in params:
                changed = True
                fixed = bm.group(1) + 'BuildContext context' + bm.group(3)
                class_body_fixed = class_body[:bm.start()] + fixed + class_body[bm.end():]
                new = new[:brace_idx+1] + class_body_fixed + new[end_idx:]

    return new, changed


def find_dart_files(paths):
    for path in paths:
        if os.path.isfile(path) and path.endswith('.dart'):
            yield path
        elif os.path.isdir(path):
            for root, _, files in os.walk(path):
                for f in files:
                    if f.endswith('.dart'):
                        yield os.path.join(root, f)


def process_file(path, apply=False):
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()
    new, changed = fix_signature(src)
    if not changed:
        return False, None
    if apply:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new)
        return True, None
    else:
        diff = '\n'.join(unified_diff(
            src.splitlines(), new.splitlines(),
            fromfile=path, tofile=path + ' (fixed)'))
        return True, diff


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('paths', nargs='+', help='Files or directories to scan')
    parser.add_argument('--apply', action='store_true', help='Apply changes')
    args = parser.parse_args()

    any_changes = False
    for p in args.paths:
        for f in find_dart_files([p]):
            changed, diff = process_file(f, apply=args.apply)
            if changed:
                any_changes = True
                if args.apply:
                    print(f'Updated: {f}')
                else:
                    print(diff)

    if not any_changes:
        print('No signature fixes proposed.')


if __name__ == '__main__':
    main()
