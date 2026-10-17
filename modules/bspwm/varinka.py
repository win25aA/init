#!/usr/bin/env python3
"""Session-local X11 helpers for the original gh0stzk Varinka Polybar.
No sudo, configuration mutation, shell evaluation of filenames, or automatic upgrades.
"""
import calendar
import datetime as dt
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess as sp
import sys
import time

HOME = Path.home()
ROOT = Path(os.environ.get('VARINKA_ROOT', Path(__file__).parent))
CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', HOME / '.config'))
STATE = HOME / '.local/state/varinka'  # Same explicit path as the Matugen template.
STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
SETTINGS = json.loads((CONFIG / 'bspwm/varinka/settings.json').read_text())
ENV = os.environ.copy()
ENV.update(XDG_CURRENT_DESKTOP='bspwm', XDG_SESSION_DESKTOP='bspwm',
           XDG_SESSION_TYPE='x11', QT_QPA_PLATFORM='xcb', GDK_BACKEND='x11',
           SDL_VIDEODRIVER='x11')
for key in ('WAYLAND_DISPLAY', 'SWAYSOCK', 'HYPRLAND_INSTANCE_SIGNATURE',
            'NIXOS_OZONE_WL', 'GBM_BACKEND', 'WLR_NO_HARDWARE_CURSORS'):
    ENV.pop(key, None)
ENV['CM_SELECTIONS'] = 'clipboard'
ENV['CM_DIR'] = str(RUNTIME)
ENV['CM_LAUNCHER'] = 'rofi'
PALETTE_DEFAULT = {
    'surface': '#212529', 'surface_container': '#2c3136',
    'surface_variant': '#495057', 'surface_container_highest': '#41484f',
    'on_surface': '#f8f9fa', 'on_surface_variant': '#ced4da',
    'primary': '#dee2e6', 'on_primary': '#212529', 'secondary': '#adb5bd',
    'tertiary': '#e9ecef', 'error': '#dee2e6',
    'outline': '#8c8c8c', 'outline_variant': '#495057',
}

def run(args, *, check=False, timeout=20, data=None, binary=False, env=None, pass_fds=()):
    return sp.run([str(x) for x in args], input=data, capture_output=True,
                  text=not binary, timeout=timeout, check=check, env=env or ENV, pass_fds=pass_fds)

def text(args, default='', timeout=20):
    try:
        p = run(args, timeout=timeout)
        return p.stdout.strip() if p.returncode == 0 else default
    except (OSError, sp.TimeoutExpired):
        return default

def atomic(path, data):
    path = Path(path)
    tmp = path.with_name(path.name + f'.tmp-{os.getpid()}')
    try:
        tmp.write_text(data)
        tmp.chmod(0o600)
        tmp.replace(path)
    finally:
        tmp.unlink(missing_ok=True)

def write_json(path, value):
    atomic(path, json.dumps(value, ensure_ascii=False, indent=2) + '\n')

def read_json(path, default):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return default

def notify(title, body='', urgency='normal'):
    try:
        run(['notify-send', '-a', 'Varinka', '-u', urgency, title, body], timeout=4)
    except (OSError, sp.TimeoutExpired):
        pass

def log(message):
    print(f'{dt.datetime.now().isoformat(timespec="seconds")} {message}',
          file=sys.stderr, flush=True)

def palette():
    p = read_json(STATE / 'colors.json', PALETTE_DEFAULT)
    if not isinstance(p, dict) or any(
            not re.fullmatch(r'#[0-9a-fA-F]{6}', str(p.get(k, '')))
            for k in PALETTE_DEFAULT):
        raise ValueError('Некорректный colors.json Matugen; предыдущая тема сохранена.')
    return p

def in_bspwm():
    # Do not touch Xwayland or the notification server of Sway/Hyprland.
    return (os.environ.get('XDG_SESSION_TYPE') == 'x11'
            and 'bspwm' in os.environ.get('XDG_CURRENT_DESKTOP', '').lower()
            and bool(text(['bspc', 'query', '-M'])))

def render_theme():
    p = palette()
    colors = {
        'bg': '#FA' + p['surface'][1:], 'bg-alt': p['outline_variant'],
        'fg': p['on_surface'], 'red': p['primary'], 'pink': p['tertiary'],
        'purple': p['on_surface_variant'], 'blue': p['outline_variant'],
        'cyan': p['secondary'], 'teal': p['tertiary'], 'green': p['secondary'],
        'lime': p['tertiary'], 'yellow': p['tertiary'], 'amber': p['secondary'],
        'orange': p['error'], 'brown': p['secondary'], 'grey': p['outline'],
        'indigo': p['tertiary'], 'blue-gray': p['outline'],
    }
    atomic(STATE / 'colors.ini', '[color]\n' + '\n'.join(
        f'{k} = {v}' for k, v in colors.items()) + '\n')
    rofi = ('* {\n'
            f'  background: {p["surface"]};\n'
            f'  foreground: {p["on_surface"]};\n'
            f'  selected: {p["primary"]};\n'
            f'  on-selected: {p["on_primary"]};\n'
            f'  outline: {p["outline_variant"]};\n' + '}\n')
    atomic(STATE / 'rofi.rasi', rofi + (ROOT / 'templates/rofi-layout.rasi').read_text())
    dunst = '''[global]
    monitor = 0
    follow = mouse
    origin = top-right
    offset = (20, 55)
    width = (250, 420)
    height = (0, 300)
    notification_limit = 5
    font = Maple Mono NF 10
    markup = full
    format = "<b>%s</b>\\n%b"
    padding = 12
    horizontal_padding = 12
    frame_width = 2
    corner_radius = 10
    transparency = 8
    separator_height = 2
    history_length = 100
    sticky_history = yes
    show_age_threshold = 60
    mouse_left_click = do_action, close_current
    mouse_middle_click = close_all
    mouse_right_click = close_current
'''
    for level, timeout, accent in [('low', 4, 'outline_variant'),
                                  ('normal', 7, 'primary'), ('critical', 0, 'error')]:
        dunst += (f'\n[urgency_{level}]\n    timeout = {timeout}\n'
                  f'    background = "{p["surface"]}"\n'
                  f'    foreground = "{p["on_surface"]}"\n'
                  f'    frame_color = "{p[accent]}"\n')
    atomic(STATE / 'dunstrc', dunst)

def owned_pid(pid, kind):
    try:
        proc = Path('/proc') / str(int(pid))
        if proc.stat().st_uid != os.getuid():
            return False
        cmd = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode(errors='replace')
        return kind in cmd
    except (ValueError, ProcessLookupError, OSError):
        return False

def reload_colors():
    render_theme()
    if not in_bspwm():
        return
    p = palette()
    for name, value in {'normal_border_color': p['outline_variant'],
                        'active_border_color': p['secondary'],
                        'focused_border_color': p['primary'],
                        'presel_feedback_color': p['primary']}.items():
        run(['bspc', 'config', name, value])
    session = read_json(STATE / 'processes.json', {})
    if owned_pid(session.get('dunst', 0), 'dunst'):
        run(['dunstctl', 'reload', str(STATE / 'dunstrc')])
    for pid in read_json(STATE / 'bars.json', []):
        if owned_pid(pid, 'polybar'):
            run(['polybar-msg', '-p', str(pid), 'cmd', 'restart'])
    # Only reload Kitty instances on this DISPLAY, not every session of the user.
    for proc in Path('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            if proc.stat().st_uid != os.getuid() or (proc / 'comm').read_text().strip() != 'kitty':
                continue
            env = (proc / 'environ').read_bytes().split(b'\0')
            if ('DISPLAY=' + ENV.get('DISPLAY', '')).encode() in env:
                os.kill(int(proc.name), signal.SIGUSR1)
        except (OSError, ValueError):
            pass

def menu(prompt, entries, *, message=None, icons=None, grid=False):
    if not (STATE / 'rofi.rasi').exists():
        render_theme()
    args = ['rofi', '-dmenu', '-i', '-no-custom', '-format', 'i', '-p', prompt,
            '-theme', str(STATE / 'rofi.rasi')]
    if message:
        args += ['-mesg', message]
    if grid:
        args += ['-theme-str', 'window { width: 900px; } listview { columns: 3; lines: 3; } '
                 'element { orientation: vertical; } element-icon { size: 160px; }']
    lines = []
    for i, entry in enumerate(entries):
        line = str(entry).replace('\n', ' ').replace('\x00', '')
        if icons:
            line += '\x00icon\x1f' + str(icons[i])
        lines.append(line)
    p = run(args, data='\n'.join(lines), timeout=None)
    if p.returncode != 0 or not p.stdout.strip().isdigit():
        return None
    n = int(p.stdout.strip())
    return n if 0 <= n < len(entries) else None

def confirm(message):
    return menu('Подтверждение', ['Отмена', 'Да'], message=message) == 1

def popen(args, name, env=None):
    log_file = (STATE / f'{name}.log').open('ab', buffering=0)
    try:
        return sp.Popen([str(x) for x in args], env=env or ENV,
                        stdout=log_file, stderr=log_file, start_new_session=True)
    finally:
        log_file.close()

def parse_xrandr(data):
    outputs = {}
    name = None
    for line in data.splitlines():
        header = re.match(r'^(\S+) connected\b', line)
        if header:
            name = header.group(1)
            outputs[name] = {'modes': {}}
        elif line and not line[0].isspace():
            name = None
        elif name:
            mode = re.match(r'^\s+(\d+x\d+)\s+(.+)$', line)
            if mode:
                rates = re.findall(r'\d+\.\d+', mode.group(2))
                outputs[name]['modes'][mode.group(1)] = rates
    return outputs

def monitors():
    outputs = parse_xrandr(text(['xrandr', '--query']))
    if not outputs:
        raise RuntimeError('Xrandr не нашёл подключённых мониторов.')
    def choose(which, exclude=None):
        explicit = SETTINGS[which + 'Output']
        if explicit:
            if explicit not in outputs or explicit == exclude:
                raise RuntimeError(f'Неверное имя X11-монитора: {explicit}')
            return explicit
        candidates = [n for n, v in outputs.items()
                      if n != exclude and SETTINGS[which + 'Mode'] in v['modes']]
        if len(candidates) == 1:
            return candidates[0]
        available = [n for n in outputs if n != exclude]
        if not available:
            return None
        # Safe first-login fallback, with a visible warning rather than a modeline.
        selected = candidates[0] if candidates else available[0]
        log(f'Неоднозначное определение {which}; выбрано {selected}. Задай Output в bspwm.nix.')
        return selected
    primary = choose('primary')
    secondary = choose('secondary', primary)
    args = ['xrandr']
    for which, name in [('primary', primary), ('secondary', secondary)]:
        if not name:
            continue
        mode = SETTINGS[which + 'Mode']
        args += ['--output', name]
        if mode in outputs[name]['modes']:
            args += ['--mode', mode]
            rates = outputs[name]['modes'][mode]
            if rates:
                rate = min(rates, key=lambda r: abs(float(r) - float(SETTINGS[which + 'Rate'])))
                if abs(float(rate) - float(SETTINGS[which + 'Rate'])) < 0.3:
                    args += ['--rate', rate]
                else:
                    log(f'{name}: частота {SETTINGS[which + "Rate"]} отсутствует; использую штатную.')
        else:
            args += ['--auto']
            log(f'{name}: режим {mode} отсутствует; не создаю непроверенный modeline.')
        args += ['--pos', SETTINGS[which + 'Position']]
        if which == 'primary':
            args += ['--primary']
    result = run(args)
    if result.returncode:
        log('Xrandr: ' + result.stderr)
    for _ in range(30):
        known = text(['bspc', 'query', '-M', '--names']).splitlines()
        if primary in known and (not secondary or secondary in known):
            break
        time.sleep(0.1)
    assignments = [(primary, list(range(1, 6)) if secondary else list(range(1, 11)))]
    if secondary:
        assignments.append((secondary, list(range(6, 11))))
    for monitor, numbers in assignments:
        names = text(['bspc', 'query', '-D', '-m', monitor, '--names']).splitlines()
        for i, number in enumerate(numbers):
            number = str(number)
            current = text(['bspc', 'query', '-D', '-d', number])
            if current:
                run(['bspc', 'desktop', current, '-m', monitor])
            elif i == 0 and names == ['Desktop']:
                ids = text(['bspc', 'query', '-D', '-m', monitor]).splitlines()
                if ids:
                    run(['bspc', 'desktop', ids[0], '-n', number], check=True)
                else:
                    run(['bspc', 'monitor', monitor, '-a', number], check=True)
            else:
                run(['bspc', 'monitor', monitor, '-a', number], check=True)
    write_json(STATE / 'outputs.json', {'primary': primary, 'secondary': secondary})
    # sxhkd -m 1 keeps letter shortcuts stable when the active group is Russian.
    run(['setxkbmap', '-layout', 'us,ru', '-option', '', '-option', 'grp:alt_shift_toggle'])

def system_ini():
    interface = ''
    routes = text(['ip', '-json', 'route', 'get', '1.1.1.1'])
    try:
        interface = json.loads(routes)[0]['dev']
    except (ValueError, IndexError, KeyError):
        names = sorted(p.name for p in Path('/sys/class/net').iterdir() if p.name != 'lo')
        interface = names[0] if names else 'lo'
    supply = Path('/sys/class/power_supply')
    battery, adapter = 'BAT0', 'AC'
    if supply.exists():
        for p in supply.iterdir():
            kind = (p / 'type').read_text().strip() if (p / 'type').exists() else ''
            if kind == 'Battery': battery = p.name
            elif kind == 'Mains': adapter = p.name
    graphics = next(iter(Path('/sys/class/backlight').glob('*')), None)
    atomic(STATE / 'system.ini', '[system]\n'
           f'sys_network_interface = {interface}\n'
           f'sys_battery = {battery}\nsys_adapter = {adapter}\n'
           f'sys_graphics_card = {graphics.name if graphics else "none"}\n')

def stop_pid(pid, kind):
    if owned_pid(pid, kind):
        try:
            os.kill(int(pid), signal.SIGTERM)
        except ProcessLookupError:
            pass

def bars():
    for pid in read_json(STATE / 'bars.json', []):
        stop_pid(pid, 'polybar')
    system_ini()
    env = ENV.copy()
    env['VARINKA_COLORS'] = str(STATE / 'colors.ini')
    env['VARINKA_SYSTEM'] = str(STATE / 'system.ini')
    outputs = text(['polybar', '--list-monitors']).splitlines()
    primary = read_json(STATE / 'outputs.json', {}).get('primary')
    outputs.sort(key=lambda line: line.split(':', 1)[0] != primary)
    pids = []
    for line in outputs:
        name = line.split(':', 1)[0]
        if not name:
            continue
        env_mon = dict(env, MONITOR=name)
        proc = popen(['polybar', '-c', CONFIG / 'polybar/varinka/config.ini', 'varinka-bar'],
                     'polybar-' + re.sub(r'[^a-zA-Z0-9_.-]', '_', name), env_mon)
        pids.append(proc.pid)
        time.sleep(0.5)  # Give the primary bar first chance to own the single XEmbed tray.
    write_json(STATE / 'bars.json', pids)

def current_wallpaper():
    saved = read_json(STATE / 'wallpaper.json', {})
    path = Path(saved.get('path', SETTINGS['initialWallpaper']))
    return path if path.is_file() else None

def set_wallpaper(path, quiet=False):
    path = Path(path).expanduser().resolve(strict=True)
    if not path.is_file():
        raise RuntimeError('Выбран не файл обоев.')
    with (STATE / 'wallpaper.lock').open('w') as lockfile:
        fcntl.flock(lockfile, fcntl.LOCK_EX)
        # The existing user templates (Kitty/GTK/btop/fish/mpv) remain in use.
        # Wallpaper is NOT changed if Matugen fails.
        p = run(['matugen', 'image', str(path), '--type', 'scheme-content',
                 '--source-color-index', '0'], timeout=180)
        if p.returncode:
            log(p.stderr)
            raise RuntimeError('Matugen завершился с ошибкой. Обои не изменены; см. session.log.')
        palette()  # Validate generated output before touching the wallpaper.
        reload_colors()  # Idempotent, even if Matugen's post-hook already ran.
        run(['feh', '--no-fehbg', '--bg-fill', str(path)], check=True)
        write_json(STATE / 'wallpaper.json', {'path': str(path)})
    if not quiet:
        notify('Обои и Matugen', path.name)

def wallpaper(args):
    if args and args[0] == '--restore':
        path = current_wallpaper()
        if path:
            set_wallpaper(path, quiet=True)
        else:
            log('Начальные обои не найдены. Выбери существующий файл через Super+Shift+W.')
        return
    if args:
        set_wallpaper(args[0]); return
    directory = Path(SETTINGS['wallpaperDirectory'])
    paths = sorted((p for p in directory.rglob('*') if p.is_file()
                    and p.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp', '.bmp')
                    and not any(c in str(p) for c in ('\n', '\x1f'))), key=lambda p: str(p).lower())
    if not paths:
        notify('Обои', f'Нет изображений в {directory}'); return
    n = menu('Обои', [str(p.relative_to(directory)) for p in paths], icons=paths, grid=True)
    if n is not None:
        set_wallpaper(paths[n])

def screenshot(kind):
    directory = Path(SETTINGS['screenshotDirectory']).expanduser()
    directory.mkdir(parents=True, exist_ok=True)
    # --raw returns the accepted image, including annotations from the region editor.
    # No clipboard copy is forced. Cancel leaves no empty file.
    command = ['flameshot', 'full' if kind == 'full' else 'gui', '--raw']
    result = run(command, binary=True, timeout=None)
    if result.returncode or not result.stdout.startswith(b'\x89PNG\r\n\x1a\n'):
        if result.stderr:
            log(result.stderr.decode(errors='replace'))
        return
    stamp = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S_%f')
    path = directory / f'Screenshot_{stamp}.png'
    with path.open('xb') as f:
        f.write(result.stdout)
    notify('Скриншот сохранён', str(path))

def media(action):
    if action != 'status':
        run(['playerctl', action]); return
    state = text(['playerctl', 'status'])
    toggle = '' if state == 'Playing' else ''
    # Preserve upstream glyphs and spacing; action targets are MPRIS, not a fake MPD server.
    print(f'%{{A1:varinka media previous:}} %{{T2}}%{{A}}'
          f'%{{A1:varinka media play-pause:}} %{{T2}}{toggle}%{{A}}'
          '%{A1:varinka media next:} %{T2}%{A}%{T-}')

def notifications():
    def unwrap(value):
        if isinstance(value, dict) and 'data' in value and 'type' in value:
            return unwrap(value['data'])
        if isinstance(value, dict): return {k: unwrap(v) for k, v in value.items()}
        if isinstance(value, list): return [unwrap(v) for v in value]
        return value
    def collect(value):
        if isinstance(value, dict):
            if 'id' in value and 'summary' in value: return [value]
            return sum((collect(v) for v in value.values()), [])
        if isinstance(value, list): return sum((collect(v) for v in value), [])
        return []
    history = collect(unwrap(read_json_string(text(['dunstctl', 'history']), {})))
    choices = ['Не беспокоить: переключить', 'Очистить историю']
    choices += [re.sub(r'<[^>]*>', '', str(x.get('summary', ''))) for x in history]
    n = menu('Уведомления', choices)
    if n == 0: run(['dunstctl', 'set-paused', 'toggle'])
    elif n == 1:
        if confirm('Очистить историю уведомлений?'): run(['dunstctl', 'history-clear'])
    elif n is not None: run(['dunstctl', 'history-pop', str(history[n - 2]['id'])])

def read_json_string(value, default):
    try: return json.loads(value)
    except ValueError: return default

def lock(nofork=False):
    p = palette()
    args = ['i3lock-color', '--color', p['surface'][1:], '--clock', '--indicator',
            '--show-keyboard-layout', '--time-str', '%H:%M', '--date-str', '%d.%m.%Y',
            '--ring-color', p['primary'][1:] + 'ff',
            '--inside-color', p['surface'][1:] + 'e8',
            '--time-color', p['on_surface'][1:] + 'ff',
            '--date-color', p['on_surface_variant'][1:] + 'ff',
            '--wrong-color', p['error'][1:] + 'ff']
    if nofork: args += ['--nofork']
    sleep_fds = ()
    if nofork and ENV.get('XSS_SLEEP_LOCK_FD', '').isdigit():
        fd = int(ENV['XSS_SLEEP_LOCK_FD'])
        try:
            os.fstat(fd)
            sleep_fds = (fd,)
        except OSError:
            pass
    # Keep xss-lock's delay inhibitor open until i3lock has grabbed the screen.
    result = run(args, timeout=None, pass_fds=sleep_fds)
    if result.returncode:
        raise RuntimeError('Не удалось заблокировать экран. Сон отменён.')

def power():
    actions = ['Блокировка', 'Сон', 'Выйти из bspwm', 'Перезагрузка', 'Выключение']
    n = menu('Сессия', actions)
    if n == 0: lock()
    elif n == 1:
        lock(); run(['systemctl', 'suspend'], check=True)
    elif n in (2, 3, 4) and confirm(actions[n] + '?'):
        if n == 2: run(['bspc', 'quit'])
        else: run(['systemctl', 'reboot' if n == 3 else 'poweroff'], check=True)

def nightlight():
    flag = STATE / 'nightlight'
    if flag.exists():
        run(['redshift', '-x'], check=True); flag.unlink(); notify('Ночной свет', 'Выключен')
    else:
        run(['redshift', '-P', '-O', '4500'], check=True)
        flag.touch(); notify('Ночной свет', '4500 K')

def audio(action):
    cmds = {'up': ['wpctl', 'set-volume', '-l', '1.5', '@DEFAULT_AUDIO_SINK@', '5%+'],
            'down': ['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', '5%-'],
            'mute': ['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle'],
            'mic': ['wpctl', 'set-mute', '@DEFAULT_AUDIO_SOURCE@', 'toggle']}
    run(cmds[action], check=True)
    device = '@DEFAULT_AUDIO_SOURCE@' if action == 'mic' else '@DEFAULT_AUDIO_SINK@'
    value = text(['wpctl', 'get-volume', device])
    number = re.search(r'([0-9.]+)', value)
    level = int(float(number.group(1)) * 100) if number else 0
    run(['notify-send', '-a', 'Varinka', '-h', 'string:x-dunst-stack-tag:volume',
         '-h', f'int:value:{level}', 'Микрофон' if action == 'mic' else 'Громкость',
         'Выключено' if 'MUTED' in value else f'{level}%'])

def updates(action):
    status = STATE / 'updates-status'
    if action == 'status':
        print(status.read_text().strip() if status.exists() else '?'); return
    if action == 'info':
        menu('Обновления NixOS', ['Закрыть'], message=(
            '? — ещё не проверено; 0 — nixpkgs совпадает с unstable; ↑ — отличается.\n'
            'Это не число пакетов. Клик слева проверяет ветку без изменения flake.lock.\n'
            'Обновление выполняй сам из /etc/nixos после проверки изменений.')); return
    lockdata = read_json(Path(SETTINGS['configurationDirectory']) / 'flake.lock', {})
    nodes = lockdata.get('nodes', {})
    node_name = nodes.get(lockdata.get('root', 'root'), {}).get('inputs', {}).get('nixpkgs', 'nixpkgs')
    old = nodes.get(node_name, {}).get('locked', {}).get('rev') if isinstance(node_name, str) else None
    notify('Nixpkgs', 'Проверяю unstable, не изменяя flake.lock…')
    p = run(['nix', 'flake', 'metadata', '--json', '--refresh', '--no-write-lock-file',
             'github:NixOS/nixpkgs/nixos-unstable'], timeout=180)
    latest = read_json_string(p.stdout, {}).get('locked', {}).get('rev') if not p.returncode else None
    value = ('0' if old == latest else '↑') if old and latest else '?'
    atomic(status, value + '\n')
    notify('Nixpkgs', 'Совпадает с unstable' if value == '0' else
           ('Закреплённая ревизия отличается от unstable' if value == '↑' else 'Проверка не удалась'))

def control():
    choices = ['Громкость и устройства', 'Сеть', 'Bluetooth', 'Обои и Matugen',
               'Буфер обмена', 'Уведомления', 'Ночной свет: переключить',
               'Скриншот области', 'Обновления: проверить nixpkgs', 'Сессия']
    n = menu('Управление', choices)
    commands = [['volume'], ['network'], ['bluetooth'], ['wallpaper'], ['clipboard'],
                ['notifications'], ['nightlight'], ['screenshot', 'region'],
                ['updates', 'check'], ['power']]
    if n is not None: dispatch(commands[n])

def session():
    # The lock prevents duplicate daemons when reloading bspwmrc.
    lockfile = (RUNTIME / 'varinka-session.lock').open('w')
    try: fcntl.flock(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError: return
    children = {}
    observer = None
    def terminate(*_): raise SystemExit(0)
    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    try:
        render_theme()
        (STATE / 'nightlight').unlink(missing_ok=True)
        observer = sp.Popen(['bspc', 'subscribe'], stdout=sp.DEVNULL, stderr=sp.DEVNULL, env=ENV)
        # Use the user's wallpaper + Matugen before starting themed clients.
        try: wallpaper(['--restore'])
        except Exception as e: log(str(e))
        commands = {
            'picom': ['picom', '--config', ROOT / 'templates/picom.conf'],
            'dunst': ['dunst', '-config', STATE / 'dunstrc'],
            'nm-applet': ['nm-applet'],
            'blueman-applet': ['blueman-applet'],
            'polkit': [os.environ['VARINKA_POLKIT_AGENT']],
            'xss-lock': ['xss-lock', '--transfer-sleep-lock', '--', 'varinka', 'lock', '--nofork'],
        }
        if SETTINGS['clipboardHistory']:
            commands['clipmenud'] = ['clipmenud']
        for name, args in commands.items():
            try: children[name] = popen(args, name)
            except OSError as e: log(f'{name}: {e}')
        write_json(STATE / 'processes.json', {k: p.pid for k, p in children.items()})
        run(['xset', 's', str(SETTINGS['autoLockSeconds'])])
        bars()
        if shutil.which('AmneziaVPN', path=ENV['PATH']):
            children['AmneziaVPN'] = popen(['AmneziaVPN'], 'AmneziaVPN')
        for name in ('primary', 'secondary'):
            selected = read_json(STATE / 'outputs.json', {}).get(name)
            if selected: log(f'{name}: {selected}')
        log('bspwm session started. Full original Varinka bar on every active monitor.')
        time.sleep(2)
        for name, proc in children.items():
            if proc.poll() is not None:
                log(f'{name} exited with {proc.returncode}; inspect {STATE / (name + ".log")}')
        observer.wait()
    finally:
        if (STATE / 'nightlight').exists():
            run(['redshift', '-x'])
            (STATE / 'nightlight').unlink(missing_ok=True)
        if observer and observer.poll() is None: observer.terminate()
        for pid in read_json(STATE / 'bars.json', []): stop_pid(pid, 'polybar')
        for proc in children.values():
            if proc.poll() is None:
                try: os.killpg(proc.pid, signal.SIGTERM)
                except ProcessLookupError: pass
        for proc in children.values():
            try: proc.wait(timeout=3)
            except sp.TimeoutExpired:
                try: os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError: pass
        (STATE / 'bars.json').unlink(missing_ok=True)
        (STATE / 'processes.json').unlink(missing_ok=True)
        lockfile.close()

def dispatch(args):
    cmd, *rest = args
    if cmd == 'session': session()
    elif cmd == 'monitors': monitors()
    elif cmd == 'reload-colors': reload_colors()
    elif cmd == 'bars': render_theme(); bars()
    elif cmd == 'wallpaper': wallpaper(rest)
    elif cmd == 'screenshot': screenshot(rest[0] if rest else 'region')
    elif cmd == 'launcher': run(['rofi', '-show', 'drun', '-theme', STATE / 'rofi.rasi'], timeout=None)
    elif cmd == 'control': control()
    elif cmd == 'notifications': notifications()
    elif cmd == 'clipboard':
        if not SETTINGS['clipboardHistory']:
            notify('Буфер обмена', 'История отключена в bspwm.nix'); return
        run(['clipmenu', '-p', 'Буфер', '-theme', STATE / 'rofi.rasi'], timeout=None)
    elif cmd == 'power': power()
    elif cmd == 'exit':
        if confirm('Выйти из bspwm?'): run(['bspc', 'quit'])
    elif cmd == 'lock': lock('--nofork' in rest)
    elif cmd == 'nightlight': nightlight()
    elif cmd == 'audio': audio(rest[0])
    elif cmd == 'media': media(rest[0] if rest else 'status')
    elif cmd == 'updates': updates(rest[0] if rest else 'status')
    elif cmd == 'network': run(['nm-connection-editor'], timeout=None)
    elif cmd == 'bluetooth': run(['blueman-manager'], timeout=None)
    elif cmd == 'volume': run(['pavucontrol'], timeout=None)
    elif cmd == 'music': run(['xdg-open', str(HOME / 'Music')], timeout=None)
    elif cmd == 'bluetooth-status':
        print('󰂯' if 'Powered: yes' in text(['bluetoothctl', 'show']) else '󰂲')
    elif cmd == 'calendar':
        today = dt.date.today()
        menu('Календарь', ['Закрыть'], message=calendar.month(today.year, today.month))
    elif cmd == 'usercard':
        menu('Система', ['Закрыть'], message=(
            f'{os.environ.get("USER", "")} · NixOS\n' + text(['uname', '-r']) + '\n' + text(['uptime', '-p'])))
    elif cmd == 'weather': print('')  # Original inactive module; plugins are intentionally not ported.
    elif cmd == 'move':
        run(['bspc', 'node', '-d', rest[0]], check=True)
        run(['bspc', 'desktop', '-f', rest[0]], check=True)
    elif cmd == 'reload':
        run(['bash', CONFIG / 'bspwm/bspwmrc'], check=True)
        run(['pkill', '-USR1', '-u', str(os.getuid()), '-x', 'sxhkd'])
        reload_colors()
    elif cmd == 'exec':
        if not rest: return
        os.execvpe(rest[0], rest, ENV)
    else: raise RuntimeError('Неизвестная команда: ' + cmd)

if __name__ == '__main__':
    os.umask(0o077)
    try:
        if len(sys.argv) < 2:
            print('varinka: wallpaper, control, power, screenshot, notifications, reload, bars'); sys.exit(0)
        dispatch(sys.argv[1:])
    except (OSError, ValueError, RuntimeError, sp.SubprocessError) as error:
        log(str(error))
        # No notification side effects when invoked by Matugen in Wayland.
        if in_bspwm(): notify('Varinka: ошибка', str(error)[:500], 'critical')
        sys.exit(1)
