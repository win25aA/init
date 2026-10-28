#!/usr/bin/env python3
"""Update only the QS palette, never application or compositor settings."""
import json, os, pathlib, re, sys, tempfile
source, dest = map(pathlib.Path, sys.argv[1:3])
colors = dict(re.findall(r'^\$([A-Za-z_][A-Za-z_0-9]*):\s*(#[0-9a-fA-F]{6,8});', source.read_text(), re.M))
colors = {key: value for key, value in colors.items() if not re.fullmatch(r'term[0-9]+', key)}
if not colors:
    raise SystemExit('No generated colors found; existing palette retained')
dest.parent.mkdir(parents=True, exist_ok=True)
fd, name = tempfile.mkstemp(prefix='.ii-colors-', dir=dest.parent)
try:
    with os.fdopen(fd, 'w') as stream:
        json.dump(colors, stream)
    os.replace(name, dest)
finally:
    if os.path.exists(name):
        os.unlink(name)
