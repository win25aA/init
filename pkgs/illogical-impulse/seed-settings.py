#!/usr/bin/env python3
"""Create writable QS preferences once; never overwrite an existing profile."""
import json, os, pathlib, tomllib
config = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', pathlib.Path.home()/'.config'))
state = pathlib.Path(os.environ.get('XDG_STATE_HOME', pathlib.Path.home()/'.local/state'))
target = config/'illogical-impulse/config.json'
if target.exists() or target.is_symlink():
    raise SystemExit(0)
wallpaper = ''
for source in [state/'noctalia/settings.toml', pathlib.Path('/etc/nixos/modules/home/desktop/wayland/noctalia/settings.toml')]:
    try:
        data = tomllib.loads(source.read_text())
        wallpaper = data.get('wallpaper', {}).get('default', {}).get('path', '')
        if wallpaper and pathlib.Path(wallpaper).is_file():
            break
    except (OSError, ValueError):
        pass
if not wallpaper or not pathlib.Path(wallpaper).is_file():
    wallpaper = os.environ['II_DEFAULT_WALLPAPER']
settings = {
    'panelFamily': 'ii',
    'background': {'wallpaperPath': wallpaper},
    'policies': {'ai': 0, 'weeb': 2},
    'appearance': {'fonts': {'main': 'Inter', 'numbers': 'Inter', 'title': 'Inter', 'reading': 'Inter', 'expressive': 'Inter'},
                   'wallpaperTheming': {'enableQtApps': False, 'enableTerminal': False}},
    'updates': {'enableCheck': False},
    'lock': {'launchOnStartup': False, 'security': {'unlockKeyring': False}},
}
target.parent.mkdir(parents=True, exist_ok=True)
try:
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except FileExistsError:
    raise SystemExit(0)
with os.fdopen(fd, 'w') as stream:
    json.dump(settings, stream, ensure_ascii=False, indent=2)
    stream.write('\n')
