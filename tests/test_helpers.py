import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess as sp
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]

class Helpers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        settings = {'screenshotDirectory': str(self.home / 'Pictures'),
                    'wallpaperDirectory': str(self.home / 'Walls'),
                    'initialWallpaper': str(self.home / 'Walls/default.png'),
                    'primaryOutput': '', 'secondaryOutput': '',
                    'primaryMode': '1440x900', 'secondaryMode': '1024x768',
                    'primaryRate': '74.98', 'secondaryRate': '70.07',
                    'primaryPosition': '0x0', 'secondaryPosition': '1440x355',
                    'clipboardHistory': True, 'autoLockSeconds': 0}
        path = self.home / '.config/bspwm/varinka/settings.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(settings))
        env = {'HOME': str(self.home), 'XDG_CONFIG_HOME': str(self.home / '.config'),
               'VARINKA_ROOT': str(ROOT / 'modules/bspwm'),
               'XDG_SESSION_TYPE': 'wayland', 'XDG_CURRENT_DESKTOP': 'sway'}
        self.envpatch = patch.dict(os.environ, env)
        self.envpatch.start()
        spec = importlib.util.spec_from_file_location('varinka_test', ROOT / 'modules/bspwm/varinka.py')
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)

    def tearDown(self):
        self.envpatch.stop()
        self.temp.cleanup()

    def test_xrandr_modes_and_rates(self):
        data = ('DVI-D-0 connected primary 1440x900+0+0\n'
                '   1440x900  74.98*+ 59.89\n'
                'HDMI-0 connected 1024x768+1440+355\n'
                '   1024x768  70.07*+ 60.00\n'
                'DP-0 disconnected\n')
        parsed = self.m.parse_xrandr(data)
        self.assertEqual(list(parsed), ['DVI-D-0', 'HDMI-0'])
        self.assertEqual(parsed['DVI-D-0']['modes']['1440x900'], ['74.98', '59.89'])

    def test_theme_generation_and_wayland_guard(self):
        with patch.object(self.m, 'run') as run:
            self.m.reload_colors()
            run.assert_not_called()
        self.assertIn('bg = #FA212529', (self.m.STATE / 'colors.ini').read_text())
        self.assertIn('corner_radius = 10', (self.m.STATE / 'dunstrc').read_text())
        self.assertIn('on-selected:', (self.m.STATE / 'rofi.rasi').read_text())

    def test_invalid_palette_keeps_previous_theme(self):
        self.m.render_theme()
        previous = (self.m.STATE / 'colors.ini').read_text()
        (self.m.STATE / 'colors.json').write_text('{"surface":"bad"}')
        with self.assertRaises(ValueError): self.m.render_theme()
        self.assertEqual(previous, (self.m.STATE / 'colors.ini').read_text())

    def test_failed_matugen_does_not_change_wallpaper(self):
        image = self.home / 'wall with spaces.png'; image.touch()
        failure = sp.CompletedProcess([], 1, '', 'test failure')
        with patch.object(self.m, 'run', return_value=failure) as run:
            with self.assertRaises(RuntimeError): self.m.set_wallpaper(image)
            self.assertEqual(run.call_count, 1)
            self.assertEqual(run.call_args.args[0][0], 'matugen')
        self.assertFalse((self.m.STATE / 'wallpaper.json').exists())

    def test_wallpaper_generates_matugen_before_feh(self):
        image = self.home / 'wall with spaces.png'; image.touch()
        success = sp.CompletedProcess([], 0, '', '')
        with patch.object(self.m, 'run', return_value=success) as run, \
                patch.object(self.m, 'reload_colors'), patch.object(self.m, 'notify'):
            self.m.set_wallpaper(image)
            calls = [call.args[0] for call in run.call_args_list]
        self.assertEqual(calls[0][0], 'matugen')
        self.assertEqual(calls[0][2], str(image.resolve()))
        self.assertEqual(calls[1], ['feh', '--no-fehbg', '--bg-fill', str(image.resolve())])
        self.assertEqual(self.m.read_json(self.m.STATE / 'wallpaper.json', {})['path'], str(image))

    def test_cancelled_screenshot_does_not_create_empty_file(self):
        with patch.object(self.m, 'run', return_value=sp.CompletedProcess([], 1, b'', b'')):
            self.m.screenshot('region')
        self.assertEqual(list((self.home / 'Pictures').glob('*')), [])

    def test_screenshot_is_saved_under_pictures(self):
        png = b'\x89PNG\r\n\x1a\n' + b'test-image'
        with patch.object(self.m, 'run', return_value=sp.CompletedProcess([], 0, png, b'')), \
                patch.object(self.m, 'notify'):
            self.m.screenshot('full')
        images = list((self.home / 'Pictures').glob('Screenshot_*.png'))
        self.assertEqual(len(images), 1)
        self.assertEqual(images[0].read_bytes(), png)

    def test_media_has_original_glyphs_and_mpris_actions(self):
        out = io.StringIO()
        with patch.object(self.m, 'text', return_value='Playing'), contextlib.redirect_stdout(out):
            self.m.media('status')
        for glyph in ('', '', ''): self.assertIn(glyph, out.getvalue())
        self.assertIn('varinka media play-pause', out.getvalue())
        self.assertTrue(out.getvalue().strip().endswith('%{T-}'))

    def test_sleep_inhibitor_fd_is_passed_to_locker(self):
        r, w = os.pipe()
        try:
            self.m.ENV['XSS_SLEEP_LOCK_FD'] = str(r)
            with patch.object(self.m, 'run', return_value=sp.CompletedProcess([], 0, '', '')) as run:
                self.m.lock(nofork=True)
            self.assertEqual(run.call_args.kwargs['pass_fds'], (r,))
            self.assertIn('--nofork', run.call_args.args[0])
        finally:
            os.close(r); os.close(w)

    def test_monitor_reload_does_not_reset_desktops(self):
        data = ('DVI-D-0 connected primary\n   1440x900  74.98*+\n'
                'HDMI-0 connected\n   1024x768  70.07*+\n')
        def fake_text(args, default='', timeout=20):
            if args[0] == 'xrandr': return data
            if args == ['bspc', 'query', '-M', '--names']: return 'DVI-D-0\nHDMI-0'
            if '-D' in args and '--names' in args:
                return '1\n2\n3\n4\n5' if 'DVI-D-0' in args else '6\n7\n8\n9\n10'
            if '-D' in args and '-d' in args: return '0x0000' + args[-1]
            return default
        with patch.object(self.m, 'text', side_effect=fake_text), \
                patch.object(self.m, 'run', return_value=sp.CompletedProcess([], 0, '', '')) as run:
            self.m.monitors()
        calls = [call.args[0] for call in run.call_args_list]
        self.assertFalse(any(args[:2] == ['bspc', 'monitor'] and '-d' in args for args in calls))
        self.assertIn('1440x355', calls[0])
        self.assertIn('74.98', calls[0])
        self.assertEqual(self.m.read_json(self.m.STATE / 'outputs.json', {})['secondary'], 'HDMI-0')

class Provenance(unittest.TestCase):
    def test_original_sources_are_unmodified(self):
        source = ROOT / 'modules/bspwm/upstream'
        hashes = json.loads((source / 'SHA256.json').read_text())
        for name, expected in hashes.items():
            self.assertEqual(hashlib.sha256((source / name).read_bytes()).hexdigest(), expected)

    def test_original_bar_geometry_fonts_and_module_lists(self):
        original = (ROOT / 'modules/bspwm/upstream/config.ini').read_text()
        adapted = (ROOT / 'modules/bspwm/polybar/config.ini').read_text()
        for key in ('width', 'height', 'offset-x', 'offset-y', 'radius', 'border-size',
                    'font-0', 'font-1', 'font-2', 'font-3',
                    'modules-left', 'modules-center', 'modules-right'):
            orig = next(line for line in original.splitlines() if line.startswith(key + ' ='))
            new = next(line for line in adapted.splitlines() if line.startswith(key + ' ='))
            self.assertEqual(orig, new, key)

if __name__ == '__main__':
    unittest.main(verbosity=2)
