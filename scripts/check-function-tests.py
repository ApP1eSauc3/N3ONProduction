#!/usr/bin/env python3
"""
check-function-tests.py — every function has one security and one performance test.

Inventory:
  Swift  N3ON/{Data,Task,Workflow,Tools,Prompt}/**/*.swift
                                                      every `func` that does not build a
                                                      view (`-> some View`) — view builders
                                                      are covered through the logic they call
  JS     amplify/backend/function/*/src/*.js          every `function name` and
                                                      `const name = (…) =>` / `async (…) =>`
  Protocol requirements (no body) are not functions and are skipped.

Each function's ID is  <Type>.<func>  (Swift; Type = innermost enclosing
type/extension) or  <function>/<file>:<func>  (JS). Overloads share one ID.

A function is covered when the tests contain BOTH
  Swift:  func test_<Type>_<func>_security…   and   func test_<Type>_<func>_performance…
  JS:     test('<function>/<file>:<func> security…')  and  test('… performance…')

Exclusions (with a reason each) live in scripts/function-test-exclusions.txt:
  <ID>  # reason

Exit 1 if any function is uncovered, or an exclusion names a function that no
longer exists. Usage:  python3 scripts/check-function-tests.py [--list]
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TYPE_RE = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:public |private |fileprivate |internal |final |open )*'
                     r'(struct|class|enum|actor|extension|protocol)\s+([A-Za-z_][A-Za-z0-9_.]*)')
FUNC_RE = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|private|fileprivate|internal|static|class|'
                     r'nonisolated|override|mutating|final|open|@objc|@discardableResult|@MainActor)\s+)*'
                     r'func\s+([A-Za-z_][A-Za-z0-9_]*)')

def swift_functions(path, skip_view_builders):
    ids = []
    stack = []          # (type name, brace depth at which it opened)
    depth = 0
    pending_type = None
    lines = open(path, encoding='utf-8').read().split('\n')
    in_block_comment = False
    for i, raw in enumerate(lines):
        line = raw
        if in_block_comment:
            if '*/' in line: in_block_comment = False; line = line.split('*/', 1)[1]
            else: continue
        if '/*' in line and '*/' not in line:
            in_block_comment = True; line = line.split('/*', 1)[0]
        code = re.sub(r'//.*', '', line)
        code = re.sub(r'"(?:\\.|[^"\\])*"', '""', code)
        if not code.strip().startswith(('func', '@')) or 'func ' not in code:
            m = TYPE_RE.match(code)
            if m and '{' in code or (m and i + 1 < len(lines)):
                if m: pending_type = (m.group(2).split('.')[-1], m.group(1))
        fm = FUNC_RE.match(code)
        if fm:
            name = fm.group(1)
            sig = code
            j = i
            while '{' not in sig and j + 1 < len(lines) and j < i + 12:
                j += 1; sig += ' ' + re.sub(r'//.*', '', lines[j])
            is_view = re.search(r'->\s*some\s+View\b', sig) is not None
            in_protocol = bool(stack) and stack[-1][2] == 'protocol'
            if not (skip_view_builders and is_view) and not in_protocol:
                owner = stack[-1][0] if stack else os.path.splitext(os.path.basename(path))[0]
                ids.append(f'{owner}.{name}')
        for ch in code:
            if ch == '{':
                depth += 1
                if pending_type:
                    stack.append((pending_type[0], depth, pending_type[1])); pending_type = None
            elif ch == '}':
                if stack and stack[-1][1] == depth: stack.pop()
                depth -= 1
    return ids

JS_FN = [re.compile(r'^\s*(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\('),
         re.compile(r'^\s*(?:const|let)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>'),
         re.compile(r'^\s*exports\.(handler)\s*=')]

def js_functions(path):
    fn = path.split('/function/')[1].split('/')[0]
    base = os.path.basename(path)
    ids = []
    for line in open(path, encoding='utf-8'):
        for r in JS_FN:
            m = r.match(line)
            if m: ids.append(f'{fn}/{base}:{m.group(1)}'); break
    return ids

def inventory():
    ids = []
    for layer in ('Data', 'Task', 'Workflow', 'Tools'):
        for p in sorted(glob.glob(f'{ROOT}/N3ON/{layer}/**/*.swift', recursive=True)):
            ids += swift_functions(p, skip_view_builders=True)
    for p in sorted(glob.glob(f'{ROOT}/N3ON/Prompt/**/*.swift', recursive=True)):
        ids += swift_functions(p, skip_view_builders=True)
    for p in sorted(glob.glob(f'{ROOT}/amplify/backend/function/*/src/*.js')):
        ids += js_functions(p)
    seen, out = set(), []
    for i in ids:
        if i not in seen: seen.add(i); out.append(i)
    return out

def tests_text():
    parts = []
    for p in glob.glob(f'{ROOT}/N3ONTests/**/*.swift', recursive=True):
        parts.append(open(p, encoding='utf-8').read())
    for p in glob.glob(f'{ROOT}/lambda-tests/*.js'):
        parts.append(open(p, encoding='utf-8').read())
    return '\n'.join(parts)

def covered(fid, text):
    if '/' in fid and ':' in fid:   # JS
        esc = re.escape(fid)
        return {k: re.search(r"test\(\s*['\"`]" + esc + r"\s+" + k, text) is not None
                for k in ('security', 'performance')}
    t, f = fid.split('.', 1)
    return {k: re.search(rf'func\s+test_{re.escape(t)}_{re.escape(f)}_{k}\w*\s*\(', text) is not None
            for k in ('security', 'performance')}

def main():
    ids = inventory()
    excl = {}
    path = f'{ROOT}/scripts/function-test-exclusions.txt'
    if os.path.exists(path):
        for line in open(path, encoding='utf-8'):
            line = line.strip()
            if not line or line.startswith('#'): continue
            fid, _, reason = line.partition('#')
            excl[fid.strip()] = reason.strip()
    text = tests_text()
    missing, stale = [], [e for e in excl if e not in ids]
    for fid in ids:
        if fid in excl: continue
        c = covered(fid, text)
        lacks = [k for k, ok in c.items() if not ok]
        if lacks: missing.append((fid, lacks))
    if '--list' in sys.argv:
        for fid in ids: print(fid + ('   [excluded: ' + excl[fid] + ']' if fid in excl else ''))
    tested = len(ids) - len(excl)
    print(f'functions: {len(ids)}  excluded: {len(excl)}  must be tested: {tested}  '
          f'fully covered: {tested - len(missing)}  missing: {len(missing)}  stale exclusions: {len(stale)}')
    for fid, lacks in missing: print(f'  MISSING {fid}: {", ".join(lacks)}')
    for e in stale: print(f'  STALE EXCLUSION {e}')
    sys.exit(1 if missing or stale else 0)

if __name__ == '__main__':
    main()
