import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import types
import unittest
from unittest.mock import patch
from PIL import Image

SOURCE=Path(__file__).resolve().parents[1]/'modules/desktop/desktop.py'
spec=importlib.util.spec_from_file_location('desktop',SOURCE)
d=importlib.util.module_from_spec(spec); spec.loader.exec_module(d)

class DesktopTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.root=Path(self.temp.name)
        self.attrs=patch.multiple(d,HOME=self.root,CFG=self.root/'cfg',CACHE=self.root/'cache',
            STATE=self.root/'state',RUNTIME=self.root/'runtime',SETTINGS={'wallpaperDirectory':str(self.root/'walls')})
        self.attrs.start(); d.setup()
        self.inactive=patch.object(d,'active_session',return_value=False); self.inactive.start()

    def tearDown(self):
        self.inactive.stop(); self.attrs.stop(); self.temp.cleanup()

    def test_matugen_palette_propagates_to_every_shell_theme(self):
        colors=dict(d.FALLBACK,primary='#123abc',surface='#101112')
        d.atom(d.CFG/'colors.json',json.dumps(colors)); d.theme_reload()
        for name in ['colors.ini','colors.rasi','dunstrc','copyq.ini','flameshot/flameshot.ini']:
            self.assertIn('#123abc',(d.CACHE/name).read_text(),name)
        for name in ['picom.conf','conky.conf']:
            self.assertIn('101112' if name=='picom.conf' else colors['on_surface'][1:],(d.CACHE/name).read_text())

    def test_wallpaper_failure_rolls_back_generated_files(self):
        wall=self.root/'test.png'; Image.new('RGB',(40,30),'red').save(wall)
        old=json.dumps(d.FALLBACK); d.atom(d.CFG/'colors.json',old)
        def fail(args,**kwargs):
            d.atom(d.CFG/'colors.json','partial corruption')
            return types.SimpleNamespace(returncode=1,stderr='test failure',stdout='')
        with patch.object(d,'run',side_effect=fail):
            with self.assertRaises(RuntimeError):d.apply_wallpaper(wall)
        self.assertEqual((d.CFG/'colors.json').read_text(),old)
        self.assertFalse((d.STATE/'wallpaper').exists())

    def test_successful_wallpaper_commits_and_uses_expected_matugen_flags(self):
        wall=self.root/'name with spaces.png'; Image.new('RGB',(40,30),'blue').save(wall)
        calls=[]
        def fake(args,**kwargs):
            calls.append((args,kwargs))
            if args[0]=='matugen':d.atom(d.CFG/'colors.json',json.dumps(d.FALLBACK))
            return types.SimpleNamespace(returncode=0,stderr='',stdout='')
        with patch.object(d,'run',side_effect=fake):d.apply_wallpaper(wall,announce=False)
        self.assertEqual((d.STATE/'wallpaper').read_text().strip(),str(wall))
        args,kwargs=calls[0]
        self.assertEqual(args,['matugen','image',str(wall),'--mode','dark','--type','scheme-content','--source-color-index','0'])
        self.assertEqual(kwargs['env']['BSPWM_THEME_DEFER'],'1')

    def test_only_images_from_configured_directory(self):
        walls=self.root/'walls'; walls.mkdir(); (walls/'sub').mkdir()
        Image.new('RGB',(40,30),'red').save(walls/'a.png')
        Image.new('RGB',(40,30),'blue').save(walls/'sub/b.jpg')
        (walls/'.face').write_text('not a wallpaper'); (walls/'test.txt').write_text('x')
        self.assertEqual(len(d.wallpapers()),2)
        thumb=d.thumbnail(walls/'a.png')
        with Image.open(thumb) as im:self.assertEqual(im.size,(496,496)); self.assertEqual(im.mode,"RGBA"); self.assertEqual(im.getpixel((0,0))[3],0)

    def test_notification_persistence_images_and_osd_exclusion(self):
        d.archive_notification(['Telegram',0,'','Title',"<b>Body</b>'",[],{},8000])
        d.archive_notification(['bspwm-osd',0,'','Volume','',[],{},1400])
        raw=bytes([255,0,0,255]*4)
        hint=types.SimpleNamespace(value=[2,2,8,True,8,4,raw])
        d.archive_notification(['Screenshot',0,'','Saved','',[],{'image-data':hint},8000])
        with d.db() as c:rows=c.execute('SELECT app,body,icon FROM notifications ORDER BY id').fetchall()
        self.assertEqual(len(rows),2); self.assertEqual(rows[0][1],"<b>Body</b>'")
        self.assertTrue(Path(rows[1][2]).exists())
        self.assertEqual((d.STATE/'notifications.sqlite3').stat().st_mode & 0o777,0o600)

    def test_flameshot_keeps_save_and_disables_upload_button(self):
        text=d.flameshot_config(d.FALLBACK)
        buttons=next(x for x in text.splitlines() if x.startswith('buttons='))
        numbers={int(x.strip()) for x in buttons.split('=',1)[1].split(',')}
        self.assertIn(11,numbers); self.assertNotIn(13,numbers)
        self.assertIn('TYPE_IMAGEUPLOADER=\n',text)
        self.assertIn('useX11LegacyScreenshot=true',text)

    def test_lock_restores_user_dnd_and_clipboard_state(self):
        calls=[]
        def output(args,default=''):
            return 'true' if args[0]=='dunstctl' else 'false'
        def run(args,**kwargs):
            calls.append(args); return types.SimpleNamespace(returncode=0,stdout='',stderr='')
        class Lock:
            def wait(self):return 0
        with patch.object(d,'output',side_effect=output),patch.object(d,'run',side_effect=run),patch.object(d.sp,'Popen',return_value=Lock()):
            d.lock_screen()
        self.assertNotIn(['dunstctl','set-paused','false'],calls)
        self.assertNotIn(['copyq','enable'],calls)
        self.assertFalse((d.RUNTIME/'locked').exists())

    def test_unread_badge(self):
        d.archive_notification(['App',0,'','New','',[],{},5000])
        with patch.object(d,'output',return_value='false'):
            self.assertTrue(d.notification_badge().endswith(' 1'))
            d.atom(d.STATE/'notifications-read','1')
            self.assertNotIn('1',d.notification_badge())

    def test_weather_network_failure_is_not_a_traceback_on_desktop(self):
        with patch.object(d.urllib.request,'urlopen',side_effect=OSError('offline')):
            self.assertIn('недоступна',d.weather_text())

class ExtraTests(DesktopTests):
    def test_native_shapes_without_font_caps(self):
        ini=(SOURCE.parent/'polybar.ini').read_text()
        for cap in ['','']:
            self.assertNotIn(cap,ini)
        self.assertIn('radius = 18',ini)
        theme=(SOURCE.parent/'wallpapers.rasi').read_text()
        self.assertIn('squared: false',theme)
        self.assertIn('border-radius: 18px',theme)

    def test_animations_and_compatible_xrender_blur(self):
        text=d.picom_config(d.FALLBACK)
        self.assertIn('preset = "appear"',text)
        self.assertIn('preset = "disappear"',text)
        self.assertNotIn('geometry-change',text)
        with patch.object(d,'SETTINGS',{'compositorBackend':'xrender'}):
            text=d.picom_config(d.FALLBACK)
            self.assertIn('blur-method = "kernel"',text)
            self.assertNotIn('dual_kawase',text)
        with patch.object(d,'SETTINGS',{'reduceMotion':True}):
            self.assertNotIn('preset =',d.picom_config(d.FALLBACK))

    def test_timeout_also_rolls_back_palette(self):
        wall=self.root/'test.png'; Image.new('RGB',(40,30),'red').save(wall)
        old=json.dumps(d.FALLBACK); d.atom(d.CFG/'colors.json',old)
        def fail(args,**kwargs):
            d.atom(d.CFG/'colors.json','partial')
            raise d.sp.TimeoutExpired(args,180)
        with patch.object(d,'run',side_effect=fail):
            with self.assertRaises(d.sp.TimeoutExpired):d.apply_wallpaper(wall)
        self.assertEqual((d.CFG/'colors.json').read_text(),old)
        self.assertFalse((d.STATE/'wallpaper').exists())

    def test_feh_failure_does_not_commit_new_theme(self):
        wall=self.root/'test.png'; Image.new('RGB',(40,30),'red').save(wall)
        old=json.dumps(d.FALLBACK); d.atom(d.CFG/'colors.json',old)
        def fake(args,**kwargs):
            if args[0]=='matugen':
                d.atom(d.CFG/'colors.json',json.dumps(dict(d.FALLBACK,primary='#abcdef')))
                return types.SimpleNamespace(returncode=0,stderr='',stdout='')
            return types.SimpleNamespace(returncode=1,stderr='test',stdout='')
        with patch.object(d,'run',side_effect=fake):
            with self.assertRaises(RuntimeError):d.apply_wallpaper(wall)
        self.assertEqual((d.CFG/'colors.json').read_text(),old)

    def test_corrupted_read_marker_is_recoverable(self):
        d.atom(d.STATE/'notifications-read','not an integer')
        with patch.object(d,'output',return_value='false'):
            self.assertTrue(d.notification_badge())

    def test_empty_workspaces_are_hidden_but_focused_is_visible(self):
        tree={'focusedDesktopId':1,'desktops':[
            {'id':1,'name':'1','root':None},
            {'id':2,'name':'2','root':None},
            {'id':3,'name':'3','root':{'client':{}}}]}
        with patch.object(d,'output',return_value=json.dumps(tree)):
            result=d.workspace_labels()
        self.assertIn('bspc desktop -f 0x1',result)
        self.assertNotIn('bspc desktop -f 0x2',result)
        self.assertIn('bspc desktop -f 0x3',result)

def load_tests(loader, tests, pattern):
    suite=loader.loadTestsFromTestCase(DesktopTests)
    suite.addTests(ExtraTests(name) for name in ExtraTests.__dict__ if name.startswith('test_'))
    return suite

if __name__=='__main__':unittest.main()
