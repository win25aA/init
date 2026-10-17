#!/usr/bin/env python3
"""X11 companion for this NixOS configuration. No shell interpolation of user data."""
import argparse
import asyncio
import configparser
import contextlib
import datetime as dt
import fcntl
import hashlib
import html
import io
import json
import logging
import os
from pathlib import Path
import re
import signal
import socket
import sqlite3
import shutil
import subprocess as sp
import sys
import tempfile
import time
import urllib.parse
import urllib.request

HOME = Path.home()
CFG = HOME / '.config/bspwm'
CACHE = Path(os.environ.get('XDG_CACHE_HOME', HOME / '.cache')) / 'bspwm'
STATE = Path(os.environ.get('XDG_STATE_HOME', HOME / '.local/state')) / 'bspwm'
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp')) / f'bspwm-{os.getuid()}'
SETTINGS = json.loads(Path(os.environ['BSPWM_DESKTOP_SETTINGS']).read_text()) if os.environ.get('BSPWM_DESKTOP_SETTINGS') else {}
# Emergency boot palette only; ordinary use replaces it with Matugen output.
FALLBACK = dict(surface='#121212', on_surface='#dddddd', surface_variant='#292929',
    on_surface_variant='#bcbcbc', primary='#c0c4c8', on_primary='#222426',
    secondary='#b5b9bd', tertiary='#c3bfc6', error='#ffb4ab', outline='#888888',
    outline_variant='#444444', surface_container='#202020', surface_container_high='#292929',
    surface_container_highest='#333333', primary_container='#3e4246', on_primary_container='#e0e4e8')
EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.tif', '.tiff'}
logging.basicConfig(level=logging.INFO, format='bspwm-desktop: %(message)s')


def setup():
    os.umask(0o077)
    for p in [CFG, CACHE, STATE, RUNTIME, CACHE/'thumbs', STATE/'notification-images']:
        p.mkdir(parents=True, exist_ok=True)


def run(args, *, check=False, text=True, input=None, timeout=20, env=None):
    return sp.run([str(x) for x in args], input=input, capture_output=True,
                  text=text, check=check, timeout=timeout, env=env)


def output(args, default=''):
    try:
        r = run(args)
        return r.stdout.strip() if r.returncode == 0 else default
    except (OSError, sp.SubprocessError):
        return default


def atom(path, content):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix='.'+path.name)
    try:
        with os.fdopen(fd, 'w') as f:
            f.write(content)
        os.replace(tmp, path)
    finally:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(tmp)


@contextlib.contextmanager
def locked(name, blocking=True):
    with (RUNTIME / (name+'.lock')).open('a') as f:
        fcntl.flock(f, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
        yield


def palette():
    p = dict(FALLBACK)
    try:
        new = json.loads((CFG/'colors.json').read_text())
        if not all(isinstance(v, str) and re.fullmatch(r'#[0-9a-fA-F]{6}', v) for v in new.values()):
            raise ValueError('Invalid Matugen colors')
        p.update(new)
    except (OSError, ValueError):
        pass
    return p


def notify(title, body='', *, icon=None):
    args = ['notify-send', '-a', 'Рабочий стол', title, body]
    if icon:
        args[1:1] = ['-i', str(icon)]
    run(args)


def active_session():
    return os.environ.get('XDG_CURRENT_DESKTOP') == 'bspwm' and os.environ.get('XDG_SESSION_TYPE') == 'x11'


def choose(rows, title, *, icons=False, theme=None, fmt=None, theme_str=None):
    args = ['rofi', '-no-config', '-dmenu', '-i', '-p', title, '-no-custom', '-theme', str(theme or CFG/'main.rasi')]
    if icons:
        args += ['-show-icons']
    if fmt:
        args += ['-format', fmt]
    if theme_str:
        args += ['-theme-str', theme_str]
    r = run(args, input='\n'.join(rows)+'\n', timeout=None)
    return r.stdout.strip() if r.returncode == 0 else None


def service(action, name):
    return run(['systemctl', '--user', action, name], timeout=30)


def theme_reload():
    if os.environ.get("BSPWM_THEME_DEFER") == "1":
        return
    p = palette()
    with locked('theme'):
        atom(CACHE/'colors.ini', '[colors]\n'+''.join(f'{k} = {v}\n' for k,v in p.items()))
        atom(CACHE/'colors.rasi', '* {\n'+''.join(f"  {k.replace('_', '-')}: {v};\n" for k,v in p.items())+'}\n')
        atom(CACHE/'dunstrc', dunst_config(p))
        atom(CACHE/'picom.conf', picom_config(p))
        atom(CACHE/'conky.conf', conky_config(p))
        atom(CACHE/'copyq.ini', '[Theme]\n'+''.join(f'{k}={v}\n' for k,v in {
            'bg':p['surface'],'fg':p['on_surface'],'alt_bg':p['surface_container'],
            'sel_bg':p['primary'],'sel_fg':p['on_primary'],'alt_sel_bg':p['primary_container'],
            'alt_sel_fg':p['on_primary_container']}.items()))
        # Keep Flameshot settings separate from its GUI-generated private state.
        flame_dir = CACHE/'flameshot'
        flame_dir.mkdir(exist_ok=True)
        atom(flame_dir/'flameshot.ini', flameshot_config(p))
    if active_session():
        if service('is-active', 'bspwm-notifications.service').returncode == 0:
            run(['dunstctl', 'reload', str(CACHE/'dunstrc')])
        if service('is-active', 'bspwm-copyq.service').returncode == 0:
            copyq_theme()
        for name in ['bspwm-polybar', 'bspwm-picom', 'bspwm-weather-widget']:
            # try-restart doesn't start X11 programs in a session where they are stopped.
            service('try-restart', name+'.service')
        for sock in Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp')).glob('kitty-*'):
            if sock.is_socket():
                run(['kitty', '@', '--to', 'unix:'+str(sock), 'set-colors', '--all', '--configured',
                     str(HOME/'.config/kitty/matugen-colors.conf')])
        fish = HOME/'.config/fish/matugen-colors.fish'
        if fish.exists():
            run(['fish', '-c', 'source "$HOME/.config/fish/matugen-colors.fish"'])
        output(['bspc', 'config', 'focused_border_color', p['primary']])
        output(['bspc', 'config', 'normal_border_color', p['outline_variant']])


def dunst_config(p):
    return f'''[global]
monitor = 0
follow = keyboard
origin = top-right
offset = (16, 72)
width = (320, 360)
height = (0, 200)
notification_limit = 5
font = DejaVu Sans 10
markup = full
format = "<b>%s</b>\\n%b"
word_wrap = true
ellipsize = end
padding = 18
horizontal_padding = 20
frame_width = 1
separator_height = 4
separator_color = frame
corner_radius = 18
icon_position = left
min_icon_size = 32
max_icon_size = 80
enable_recursive_icon_lookup = true
icon_theme = Papirus-Dark, Papirus, Adwaita
show_indicators = true
progress_bar = true
progress_bar_height = 6
history_length = 200
sticky_history = false
idle_threshold = 120
mouse_left_click = do_action
mouse_middle_click = close_current
mouse_right_click = context
dmenu = rofi -dmenu -i -p Действие
browser = xdg-open
[urgency_low]
background = "{p['surface']}"
foreground = "{p['on_surface_variant']}"
frame_color = "{p['outline_variant']}"
timeout = 5
[urgency_normal]
background = "{p['surface']}"
foreground = "{p['on_surface']}"
frame_color = "{p['outline_variant']}"
timeout = 8
[urgency_critical]
background = "{p['surface_container_high']}"
foreground = "{p['on_surface']}"
frame_color = "{p['error']}"
timeout = 0
[osd]
appname = bspwm-osd
format = "%s"
timeout = 1400ms
history_ignore = true
override_pause_level = 100
set_transient = true
highlight = "{p['primary']}"
'''


def picom_config(p):
    # Picom 13 native presets. Xrender needs kernel blur, not dual_kawase.
    backend = SETTINGS.get('compositorBackend', 'glx')
    if backend not in ('glx', 'xrender'):
        backend = 'glx'
    text = '''backend = "glx";
vsync = true;
use-damage = false;
unredir-if-possible = false;
shadow = true;
shadow-radius = 18;
shadow-opacity = 0.20;
shadow-offset-x = 0;
shadow-offset-y = 8;
shadow-color = "@SURFACE@";
corner-radius = 18;
blur-method = "dual_kawase";
blur-strength = 4;
detect-client-opacity = true;
animations = (
  { triggers = [ "open", "show" ]; preset = "appear"; scale = 0.97; duration = 0.22; },
  { triggers = [ "close", "hide" ]; preset = "disappear"; scale = 0.98; duration = 0.15; },
  { triggers = [ "increase-opacity" ]; preset = "appear"; scale = 1.0; duration = 0.14; },
  { triggers = [ "decrease-opacity" ]; preset = "disappear"; scale = 1.0; duration = 0.14; }
);
rules = (
  { match = "window_type = 'desktop' || class_g = 'Conky' || class_g = 'BspwmScreenCorners'";
    shadow = false; corner-radius = 0; blur-background = false; animations = (); },
  { match = "class_g = 'Rofi'";
    corner-radius = 20; shadow = true; blur-background = true; },
  { match = "class_g = 'Polybar'";
    corner-radius = 18; shadow = true; blur-background = false; },
  { match = "class_g = 'Dunst'";
    corner-radius = 18; shadow = true;
    animations = (
      { triggers = [ "open", "show" ]; preset = "appear"; scale = 0.98; duration = 0.20; },
      { triggers = [ "close", "hide" ]; preset = "disappear"; scale = 0.98; duration = 0.14; }
    ); },
  { match = "fullscreen || class_g = 'i3lock' || class_g = 'flameshot' || class_g = 'Flameshot'";
    corner-radius = 0; shadow = false; blur-background = false; animations = (); }
);
'''.replace('@SURFACE@',p['surface'])
    if backend == 'xrender':
        text = text.replace('backend = "glx"', 'backend = "xrender"').replace('blur-method = "dual_kawase"', 'blur-method = "kernel"')
    if SETTINGS.get('reduceMotion', False):
        text = re.sub(r'animations = \(.*?\);', 'animations = ();', text, flags=re.S)
    return text


def flameshot_config(p):
    # CaptureTool Type enum: omit TYPE_IMAGEUPLOADER=13 and its shortcut.
    return f'''[General]
useX11LegacyScreenshot=true
uiColor={p['primary']}
contrastUiColor={p['surface']}
drawColor={p['primary']}
showStartupLaunchMessage=false
showHelp=true
savePath={HOME}/Pictures/Screenshots
savePathFixed=true
saveAfterCopy=true
showSidePanelButton=true
uploadWithoutConfirmation=false
buttons=0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22
[Shortcuts]
TYPE_IMAGEUPLOADER=
'''


def conky_config(p):
    # No background or shadow, as in the supplied weather widget.
    return '''conky.config = {
  background = false, update_interval = 15, double_buffer = true,
  own_window = true, own_window_type = 'desktop', own_window_class = 'Conky',
  own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
  own_window_transparent = true, own_window_argb_visual = true, own_window_argb_value = 0,
  alignment = 'top_left', gap_x = 16, gap_y = 54, minimum_width = 256, maximum_width = 256,
  draw_shades = false, draw_outline = false, draw_borders = false,
  use_xft = true, font = 'DejaVu Sans:size=11', default_color = '%s',
};
conky.text = [[
${font DejaVu Sans:style=Bold:size=12}Высокая Гора${font}
${execi 60 bspwm-desktop weather}
]];
''' % p['on_surface'][1:]


def wallpapers():
    root = Path(SETTINGS.get('wallpaperDirectory', '/etc/nixos/wallpapers'))
    try:
        return sorted((p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in EXTENSIONS), key=lambda p:str(p).casefold())
    except OSError:
        return []


def thumbnail(path):
    from PIL import Image, ImageOps, ImageDraw
    key = hashlib.sha256(('rounded-square-v3'+str(path)+str(path.stat().st_mtime_ns)).encode()).hexdigest()
    target = CACHE/'thumbs'/f'{key}.png'
    if not target.exists():
        with Image.open(path) as im:
            im = ImageOps.fit(ImageOps.exif_transpose(im).convert('RGB'), (496,496)).convert('RGBA')
            mask=Image.new('L',(1984,1984),0)
            ImageDraw.Draw(mask).rounded_rectangle((0,0,1983,1983),radius=128,fill=255)
            mask=mask.resize(im.size,Image.Resampling.LANCZOS)
            im.putalpha(mask)
            im.save(target)
    return target


def wallpaper_menu():
    files = wallpapers()
    if not files:
        notify('Обои не найдены', SETTINGS.get('wallpaperDirectory', '/etc/nixos/wallpapers'))
        return
    valid, rows = [], []
    for path in files:
        try:
            thumb = thumbnail(path)
        except Exception as e:
            logging.warning('Skipping unreadable image %s: %s', path, e)
            continue
        valid.append(path)
        rows.append(str(len(valid))+'\0icon\x1f'+str(thumb)+'\x1fdisplay\x1f ')
    selected = choose(rows, 'Обои', icons=True, theme=CFG/'wallpapers.rasi', fmt='i',
        theme_str='listview { lines: '+str(min(2,(len(valid)+2)//3))+'; }')
    if selected is not None:
        try:
            path = valid[int(selected)]
        except (ValueError, IndexError):
            return
        apply_wallpaper(path)


def apply_wallpaper(path, announce=True):
    path = Path(path).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError(path)
    with locked('wallpaper'):
        # Keep a reversible copy: a failed Matugen run must not commit half a theme.
        backups = {}
        targets = [CFG/'colors.json', HOME/'.config/kitty/matugen-colors.conf',
            HOME/'.config/btop/themes/matugen.theme', HOME/'.config/fish/matugen-colors.fish',
            HOME/'.config/gtk-3.0/matugen-colors.css', HOME/'.config/gtk-4.0/matugen-colors.css',
            HOME/'.config/mpv/matugen-colors.conf']
        for f in targets:
            backups[f] = f.read_text() if f.is_file() else None
        try:
            r = run(['matugen','image',str(path),'--mode','dark','--type','scheme-content',
                     '--source-color-index','0'], timeout=180,
                    env=dict(os.environ,BSPWM_THEME_DEFER='1'))
            if r.returncode:
                raise RuntimeError('Matugen: '+r.stderr[-1800:])
            r = run(['feh','--no-fehbg','--bg-fill',str(path)], timeout=40)
            if r.returncode:
                raise RuntimeError('Feh: '+r.stderr[-1800:])
        except Exception:
            for f, content in backups.items():
                if content is not None:
                    atom(f,content)
                else:
                    f.unlink(missing_ok=True)
            theme_reload()
            raise
        atom(STATE/'wallpaper', str(path)+'\n')
        theme_reload()
        if announce:
            notify('Обои и цвета применены', path.name)


def bootstrap():
    for path in [HOME/'.config/kitty', HOME/'.config/btop/themes', HOME/'.config/fish',
                 HOME/'.config/gtk-3.0', HOME/'.config/gtk-4.0', HOME/'.config/mpv']:
        path.mkdir(parents=True, exist_ok=True)
    saved = (STATE/'wallpaper').read_text().strip() if (STATE/'wallpaper').exists() else ''
    default = SETTINGS.get('defaultWallpaper','/etc/nixos/wallpapers/wallpaperflare.com_wallpaper.jpg')
    candidates = [Path(saved), Path(default)] + wallpapers()
    path = next((p for p in candidates if p.is_file() and p.suffix.lower() in EXTENSIONS), None)
    if path:
        try:
            apply_wallpaper(path, announce=False)
            return
        except Exception:
            logging.exception('Wallpaper/theme initialization failed')
    if not (CFG/'colors.json').exists():
        r = run(['matugen','color','hex','#b8bcc8','--mode','dark','--type','scheme-content'],timeout=120)
        if r.returncode:
            logging.error('Matugen fallback failed: %s', r.stderr)
    theme_reload()
    if not path:
        logging.warning('No wallpaper in configured directory; boot palette used')


@contextlib.contextmanager
def db():
    c = sqlite3.connect(STATE/'notifications.sqlite3', timeout=5)
    c.execute('PRAGMA journal_mode=WAL')
    c.execute('CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp REAL, app TEXT, summary TEXT, body TEXT, icon TEXT)')
    try:
        with c:
            yield c
    finally:
        c.close()


def archive_notification(body):
    # FDO Notify: app_name, replaces_id, app_icon, summary, body, actions, hints, timeout.
    if len(body) != 8 or body[0] == 'bspwm-osd':
        return
    app, _, icon, title, text, _, hints, _ = body
    icon = str(icon)
    def val(key):
        v = hints.get(key)
        return getattr(v,'value',v)
    image = val('image-data') or val('image_data') or val('icon_data')
    if image:
        try:
            from PIL import Image
            w,h,stride,alpha,bits,channels,raw = image
            if bits == 8 and channels in (3,4) and 0 < w <= 8192 and 0 < h <= 8192 and len(raw) <= 64*1024*1024:
                mode = 'RGBA' if alpha else 'RGB'
                im = Image.frombytes(mode,(w,h),bytes(raw),'raw',mode,stride)
                im.thumbnail((360,240))
                buf = io.BytesIO(); im.save(buf,format='PNG')
                target = STATE/'notification-images'/(hashlib.sha256(buf.getvalue()).hexdigest()+'.png')
                target.write_bytes(buf.getvalue()); icon = str(target)
        except Exception:
            logging.exception('Notification image could not be decoded')
    elif val('image-path'):
        icon = str(val('image-path'))
    with db() as c:
        c.execute('INSERT INTO notifications(timestamp,app,summary,body,icon) VALUES(?,?,?,?,?)',
                  (time.time(),str(app),str(title),str(text),icon))
        c.execute('DELETE FROM notifications WHERE id NOT IN (SELECT id FROM notifications ORDER BY id DESC LIMIT 500)')
    # Keep the private image cache bounded too.
    with db() as c:
        referenced = {row[0] for row in c.execute('SELECT icon FROM notifications')}
    for f in (STATE/'notification-images').glob('*.png'):
        if str(f) not in referenced:
            f.unlink(missing_ok=True)


async def notification_monitor():
    from dbus_next.aio import MessageBus
    from dbus_next import Message, MessageType
    bus = await MessageBus().connect()
    def receive(msg):
        if msg.message_type == MessageType.METHOD_CALL and msg.interface == 'org.freedesktop.Notifications' and msg.member == 'Notify':
            try:
                archive_notification(msg.body)
            except Exception:
                logging.exception('Notification archive error')
        # A monitor must never send replies to observed calls.
        return msg.message_type == MessageType.METHOD_CALL
    bus.add_message_handler(receive)
    reply = await bus.call(Message(destination='org.freedesktop.DBus', path='/org/freedesktop/DBus',
        interface='org.freedesktop.DBus.Monitoring', member='BecomeMonitor', signature='asu',
        body=[["type='method_call',interface='org.freedesktop.Notifications',member='Notify'"],0]))
    if reply.message_type == MessageType.ERROR:
        raise RuntimeError('D-Bus notification monitoring denied: '+str(reply.body))
    address = os.environ.get('NOTIFY_SOCKET')
    if address:
        with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as ready:
            ready.connect('\0'+address[1:] if address.startswith('@') else address)
            ready.sendall(b'READY=1')
    await bus.wait_for_disconnect()
    raise RuntimeError('Session bus disconnected')


def plain(s):
    return re.sub(r'[\x00-\x1f\x7f]', ' ', html.unescape(re.sub('<[^>]+>','',s)))


def notifications_menu():
    with db() as c:
        entries = c.execute('SELECT id,timestamp,app,summary,body,icon FROM notifications ORDER BY id DESC').fetchall()
    paused = output(['dunstctl','is-paused']) == 'true'
    if entries:
        atom(STATE/'notifications-read',str(max(e[0] for e in entries)))
    rows = ['Не беспокоить: '+('вкл' if paused else 'выкл'), 'Закрыть всплывающие', 'Очистить историю']
    for _,stamp,app,title,body,icon in entries:
        label = dt.datetime.fromtimestamp(stamp).strftime('%d.%m %H:%M')+'  '+plain(app)+' — '+plain(title)
        rows.append(label+('\0icon\x1f'+icon if icon and '\n' not in icon else ''))
    idx = choose(rows,'Уведомления', icons=True,fmt='i')
    if idx is None:
        return
    i=int(idx)
    if i==0:
        run(['dunstctl','set-paused','toggle'])
    elif i==1:
        run(['dunstctl','close-all'])
    elif i==2:
        if choose(['Нет','Да'],'Очистить историю?') == 'Да':
            with db() as c:
                c.execute('DELETE FROM notifications')
            for f in (STATE/'notification-images').glob('*.png'):
                f.unlink(missing_ok=True)
            run(['dunstctl','history-clear'])
    elif 0 <= i-3 < len(entries):
        _,stamp,app,title,body,icon=entries[i-3]
        # Archive contains content, not live application callback handles.
        text=plain(app)+' — '+plain(title)+'\n\n'+plain(body)
        run(['zenity','--text-info','--title=Уведомление','--width=620','--height=380'],input=text,timeout=None)


def launch(args):
    if not shutil.which(args[0]):
        notify('Программа не найдена', args[0])
        return
    sp.Popen(args, stdout=sp.DEVNULL, stderr=sp.DEVNULL, start_new_session=True)


def copyq_theme():
    # loadTheme is CopyQ's supported live theme API; no clipboard daemon restart.
    run(['copyq','loadTheme',str(CACHE/'copyq.ini')])
    run(['copyq','config','maxitems','200'])


def control_menu():
    night = service('is-active','bspwm-nightlight.service').returncode == 0
    rows = ['Звук', 'Сеть', 'Bluetooth', 'Уведомления', 'История буфера', 'Обои',
            'Ночной режим: '+('вкл' if night else 'выкл'), 'Яркость', 'Медиаплеер',
            'Запись экрана', 'Снимок области', 'Сеанс']
    pick=choose(rows,'Управление')
    if pick is None:
        return
    actions={'Звук':['pavucontrol'],'Сеть':['nm-connection-editor'],'Bluetooth':['blueman-manager'],
        'История буфера':['copyq','show'],'Медиаплеер':['bspwm-desktop','media-menu'],
        'Запись экрана':['gpu-screen-recorder-gtk']}
    if pick in actions:
        launch(actions[pick])
    elif pick=='Уведомления': notifications_menu()
    elif pick=='Обои': wallpaper_menu()
    elif pick.startswith('Ночной режим:'): toggle_nightlight()
    elif pick=='Яркость': brightness_menu()
    elif pick=='Снимок области': screenshot('region')
    elif pick=='Сеанс': session_menu()


def toggle_nightlight():
    marker=STATE/'nightlight-disabled'
    if service('is-active','bspwm-nightlight.service').returncode == 0:
        marker.touch(); service('stop','bspwm-nightlight.service')
    else:
        marker.unlink(missing_ok=True); service('start','bspwm-nightlight.service')


def brightness_menu():
    devices = output(['brightnessctl','-l'])
    if 'backlight' not in devices:
        notify('Яркость недоступна', 'На этих мониторах может требоваться DDC/CI; ночной режим доступен отдельно.')
        return
    value=choose([f'{n}%' for n in range(10,101,10)],'Яркость')
    if value:
        run(['brightnessctl','set',value])


def session_menu(logout=False):
    action = 'Выйти' if logout else choose(['Заблокировать','Выйти','Сон','Перезагрузить','Выключить'],'Сеанс')
    if not action:
        return
    if action=='Заблокировать':
        lock_screen(); return
    if action=='Сон':
        run(['systemctl','suspend']); return
    if choose(['Нет','Да'],action+'?') != 'Да':
        return
    if action=='Выйти': run(['bspc','quit'])
    elif action=='Перезагрузить': run(['systemctl','reboot'])
    elif action=='Выключить': run(['systemctl','poweroff'])


def lock_screen():
    with locked('screen',blocking=False):
        was_paused = output(['dunstctl','is-paused']) == 'true'
        monitoring = output(['copyq','eval','str(monitoring())']) != 'false'
        osd_running = service('is-active','bspwm-osd.service').returncode == 0
        (RUNTIME/'locked').touch()
        if osd_running:
            service('stop','bspwm-osd.service')
        run(['dunstctl','close-all'])
        run(['dunstctl','set-paused','true']); run(['copyq','disable'])
        try:
            # For xss-lock sleep handoff: preserve FD in i3lock, not in this parent.
            fd=int(os.environ['XSS_SLEEP_LOCK_FD']) if os.environ.get('XSS_SLEEP_LOCK_FD','').isdigit() else None
            proc=sp.Popen(['i3lock','--nofork','--color',palette()['surface'][1:]], pass_fds=(fd,) if fd is not None else ())
            if fd is not None:
                os.close(fd)
            code=proc.wait()
            if code:
                raise RuntimeError('i3lock failed; check PAM and X11')
        finally:
            (RUNTIME/'locked').unlink(missing_ok=True)
            if not was_paused:
                run(['dunstctl','set-paused','false'])
            if monitoring:
                run(['copyq','enable'])
            if osd_running:
                service('start','bspwm-osd.service')


def screenshot(kind):
    target=HOME/'Pictures/Screenshots'
    target.mkdir(parents=True,exist_ok=True)
    time.sleep(.25)  # let the launcher/menu disappear
    if kind=='region':
        run(['flameshot','gui','-p',str(target)],timeout=None)
    else:
        file=target/(dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S_%f')+'.png')
        if kind=='monitor':
            r=run(['flameshot','screen','-c','-p',str(file)],timeout=40)
        else:
            r=run(['flameshot','full','-c','-p',str(file)],timeout=40)
        if r.returncode:
            raise RuntimeError(r.stderr or 'Flameshot could not capture screen')
        notify('Скриншот сохранён и скопирован',str(file),icon=file)


def polybar_start():
    for _ in range(150):
        if output(['bspc','query','-D','--names']):
            break
        time.sleep(.1)
    lines=output(['polybar','--list-monitors']).splitlines()
    main=next((line.split(':',1)[0] for line in lines if '(primary)' in line), '')
    if not main and lines:
        main=lines[0].split(':',1)[0]
    children=[]
    for line in lines:
        name=line.split(':',1)[0]
        env=os.environ.copy(); env['MONITOR']=name
        children.append(sp.Popen(['polybar','--config='+str(CFG/'polybar.ini'),'main' if name==main else 'secondary'],env=env))
    def stop(*_):
        for child in children:
            child.terminate()
        raise SystemExit(0)
    signal.signal(signal.SIGTERM,stop)
    if not children:
        raise RuntimeError('No XRandR monitors for Polybar')
    while all(child.poll() is None for child in children):
        time.sleep(.5)
    stop()


def workspace_labels():
    raw=output(['bspc','query','-T','-m',os.environ.get('MONITOR','focused')])
    if not raw:
        return ''
    tree=json.loads(raw);p=palette();result=[]
    for desk in tree.get('desktops',[]):
        focused=desk['id']==tree.get('focusedDesktopId')
        if not focused and desk.get('root') is None:
            continue
        text=plain(str(desk['name'])).replace('%','%%')
        # One flat window surface; focus is a typographic accent, not glued glyphs.
        label=f"%{{F{p['primary'] if focused else p['on_surface_variant']}}}"+('● ' if focused else '')+text+'%{F-}'
        command='bspc desktop -f '+hex(int(desk['id']))
        result.append('%{A1:'+command+':}'+label+'%{A}')
    return '  '.join(result)


def workspaces_watch():
    print(workspace_labels(),flush=True)
    with sp.Popen(['bspc','subscribe','desktop_focus','desktop_add','desktop_remove','node_add','node_remove','node_transfer','node_flag'],stdout=sp.PIPE,text=True) as events:
        for _ in events.stdout:
            print(workspace_labels(),flush=True)
    raise RuntimeError('bspwm event stream closed')


def monitor_width():
    try:
        tree=json.loads(output(['bspc','query','-T','-m',os.environ.get('MONITOR','focused')]))
        return int(tree['rectangle']['width'])
    except (ValueError,KeyError,TypeError):
        return 1440


def media_title():
    status=output(['playerctl','status'])
    if status not in ('Playing','Paused'):
        return ''
    title=plain(output(['playerctl','metadata','--format','{{ artist }} — {{ title }}'])).strip(' —')
    if not title:
        title='Медиаплеер'
    limit=25 if monitor_width()<1200 else 42
    if len(title)>limit:
        title=title[:limit-1].rstrip()+'…'
    title=title.replace('%','%%')
    return ('󰐊  ' if status=='Playing' else '󰏤  ')+title


def media_menu():
    title=output(['playerctl','metadata','--format','{{ artist }} — {{ title }}'])
    selection=choose(['Воспроизведение / пауза','Предыдущий трек','Следующий трек'],plain(title)[:60] or 'Медиа')
    commands={'Воспроизведение / пауза':'play-pause','Предыдущий трек':'previous','Следующий трек':'next'}
    if selection in commands:
        run(['playerctl',commands[selection]])


def volume_state(source=False):
    data=output(['wpctl','get-volume','@DEFAULT_AUDIO_SOURCE@' if source else '@DEFAULT_AUDIO_SINK@'])
    m=re.search(r'Volume:\s*([0-9.]+)',data)
    return (round(float(m.group(1))*100), '[MUTED]' in data) if m else None


def osd(title,value,tag):
    if (RUNTIME/'locked').exists():
        return
    run(['notify-send','-a','bspwm-osd','-t','1400','-h','string:x-dunst-stack-tag:'+tag,
        '-h','int:value:'+str(max(0,min(100,value))),'-h','boolean:transient:true',title])


def osd_watch():
    last=[volume_state(False),volume_state(True)]
    layout=output(['xkb-switch'])
    brightness=output(['brightnessctl','get'])
    # Poll actual state: also sees changes from pavucontrol, tray and external tools.
    while True:
        for i in (0,1):
            now=volume_state(bool(i))
            if now and last[i] and now!=last[i]:
                value,mute=now
                osd(('Микрофон' if i else 'Громкость')+(': выключено' if mute else f': {value}%'),0 if mute else value,'mic' if i else 'volume')
            last[i]=now
        now=output(['xkb-switch'])
        if now and layout and now!=layout:
            osd('Раскладка: '+now.upper(),0,'keyboard')
        layout=now
        now=output(['brightnessctl','get'])
        if now and brightness and now!=brightness:
            maximum=output(['brightnessctl','max'])
            if now.isdigit() and maximum.isdigit() and int(maximum)>0:
                percent=round(int(now)/int(maximum)*100)
                osd(f'Яркость: {percent}%',percent,'brightness')
        brightness=now
        time.sleep(.6)


def weather_text():
    cache=CACHE/'weather.json'
    try:
        if not cache.exists() or time.time()-cache.stat().st_mtime > 900:
            query=urllib.parse.urlencode({'latitude':SETTINGS.get('latitude',55.9122),
                'longitude':SETTINGS.get('longitude',49.3128),
                'current':'temperature_2m,apparent_temperature,weather_code,wind_speed_10m','timezone':'Europe/Moscow'})
            request=urllib.request.Request('https://api.open-meteo.com/v1/forecast?'+query,headers={'User-Agent':'bspwm-weather/1.0'})
            with urllib.request.urlopen(request,timeout=8) as r:
                payload=json.load(r)
            atom(cache,json.dumps(payload))
        current=json.loads(cache.read_text())['current']
        code=current['weather_code']
        description= ('Ясно' if code==0 else 'Облачно' if code<=3 else 'Туман' if code<=48
                      else 'Дождь' if code<=67 else 'Снег' if code<=77 else 'Осадки' if code<=86 else 'Гроза')
        stale=' · нет обновления' if time.time()-cache.stat().st_mtime>1800 else ''
        return f"{current['temperature_2m']:+.0f}°C · {description}{stale}\nОщущается {current['apparent_temperature']:+.0f}°C\nВетер {current['wind_speed_10m']:.0f} км/ч\nOpen-Meteo · CC BY 4.0"
    except Exception:
        if cache.exists():
            try:
                c=json.loads(cache.read_text())['current']
                return f"{c['temperature_2m']:+.0f}°C · нет обновления\nOpen-Meteo · CC BY 4.0"
            except Exception:
                pass
        return 'Погода временно недоступна\nOpen-Meteo · CC BY 4.0'


def notification_badge():
    try:
        read = int((STATE/'notifications-read').read_text())
    except (OSError,ValueError):
        read = 0
    with db() as c:
        count=c.execute('SELECT count(*) FROM notifications WHERE id>?',(read,)).fetchone()[0]
    bell='󰂛' if output(['dunstctl','is-paused'])=='true' else '󰂚'
    return bell+((' '+str(count)) if count else '')


def status():
    r=run(['systemctl','--user','--no-pager','--full','status','bspwm-session.target',
        'bspwm-notifications','bspwm-notification-archive','bspwm-polybar','bspwm-picom',
        'bspwm-copyq','bspwm-nightlight','bspwm-osd','bspwm-weather-widget'],timeout=20)
    print(r.stdout)
    print('Matugen palette:',CFG/'colors.json','exists:',(CFG/'colors.json').exists())
    print('Wallpaper:', (STATE/'wallpaper').read_text().strip() if (STATE/'wallpaper').exists() else 'not selected')


def main():
    setup()
    parser=argparse.ArgumentParser()
    parser.add_argument('command',choices=['bootstrap','theme-reload','wallpapers','wallpaper','notifications','control',
        'session','logout','lock','screenshot','polybar','media','media-menu','osd-watch','weather','archive','nightlight','status','notify-count','copyq-theme','workspaces'])
    parser.add_argument('argument',nargs='?')
    args=parser.parse_args()
    funcs={'bootstrap':bootstrap,'theme-reload':theme_reload,'wallpapers':wallpaper_menu,
        'notifications':notifications_menu,'control':control_menu,'session':session_menu,
        'logout':lambda:session_menu(True),'lock':lock_screen,'screenshot':lambda:screenshot(args.argument or 'region'),
        'wallpaper':lambda:apply_wallpaper(args.argument),'polybar':polybar_start,'media':lambda:print(media_title()),
        'media-menu':media_menu,'workspaces':workspaces_watch,'osd-watch':osd_watch,'weather':lambda:print(weather_text()),
        'copyq-theme':copyq_theme,'archive':lambda:asyncio.run(notification_monitor()),'nightlight':toggle_nightlight,'status':status,
        'notify-count':lambda:print(notification_badge())}
    try:
        funcs[args.command]()
    except BlockingIOError:
        pass
    except Exception as e:
        logging.exception('%s failed', args.command)
        if args.command in ['wallpapers','wallpaper','screenshot','lock']:
            with contextlib.suppress(Exception):
                notify('Ошибка рабочего стола',str(e))
        return 1
    return 0


if __name__=='__main__':
    sys.exit(main())
