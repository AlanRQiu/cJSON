#!/usr/bin/env python3
"""Deterministic seed builder. Writes trial4/seeds/parse/* and trial4/seeds/utils/* (names = sha1 prefix).
parse seeds: tests/inputs/test* (not .expected), fuzzing/inputs/* with the 2-byte AFL option prefix removed,
             plus a few small synthetic documents.
utils seeds: every {doc, patch} case in tests/json-patch-tests/{tests,spec_tests,cjson-utils-tests}.json
             as  <doc> 0x00 <patch> 0x00 <pointer>, plus a few synthetic ones. Standard library only."""
import hashlib, json, pathlib, shutil, sys
root = pathlib.Path(__file__).resolve().parent.parent.parent
out = root / "trial4" / "seeds"
shutil.rmtree(out, ignore_errors=True)
for d in ("parse", "utils"):
    (out / d).mkdir(parents=True)

def put(kind, data):
    (out / kind / hashlib.sha1(data).hexdigest()[:16]).write_bytes(data)

n = {"parse": 0, "utils": 0}
for p in sorted((root / "tests" / "inputs").glob("test*")):
    if p.suffix == ".expected": continue
    put("parse", p.read_bytes()); n["parse"] += 1
for p in sorted((root / "fuzzing" / "inputs").glob("test*")):
    b = p.read_bytes()
    put("parse", b[2:] if len(b) > 2 else b); n["parse"] += 1
for s in ['{}', '[]', '[1,2,3]', '{"a":[true,false,null,1.5e3,"\\u00e9\\ud83d\\ude00"]}', '"x"', '-0.0', '[[[[[[]]]]]]',
          '{"a":{"b":{"c":{}}}}', '[1,\n 2 ,\r\t3]']:
    put("parse", s.encode()); n["parse"] += 1

for name in ("tests.json", "spec_tests.json", "cjson-utils-tests.json"):
    cases = json.loads((root / "tests" / "json-patch-tests" / name).read_text())
    for c in cases:
        if not isinstance(c, dict) or "doc" not in c or "patch" not in c: continue
        ptr = ""
        if isinstance(c["patch"], list) and c["patch"] and isinstance(c["patch"][0], dict):
            ptr = str(c["patch"][0].get("path", ""))
        doc = json.dumps(c["doc"], separators=(",", ":")).encode()
        pat = json.dumps(c["patch"], separators=(",", ":")).encode()
        if b"\x00" in doc or b"\x00" in pat: continue
        put("utils", doc + b"\0" + pat + b"\0" + ptr.encode()); n["utils"] += 1
for doc, pat, ptr in [('{"a":1}', '{"a":null}', '/a'), ('{"a":{"b":1}}', '{"a":{"b":2,"c":3}}', '/a/b'),
                      ('[1,2,3]', '[{"op":"add","path":"/1","value":9}]', '/1'), ('{}', '[]', ''),
                      ('{"a":{"a":5}}', '{"a":5}', '/a/a'), ('[{}]', '[]', '/0')]:
    put("utils", doc.encode() + b"\0" + pat.encode() + b"\0" + ptr.encode()); n["utils"] += 1
print(f"seeds written: parse={len(list((out/'parse').iterdir()))} utils={len(list((out/'utils').iterdir()))} (before de-duplication {n})")
