#!/usr/bin/env python3
"""Click-through physical screen corner masks, X Shape extension, radius 30."""
import re
import subprocess
import time
from Xlib import X, display
from Xlib.ext import shape


def monitors(root):
    result=subprocess.run(['xrandr','--listmonitors'],capture_output=True,text=True)
    result_rect=[]
    for line in result.stdout.splitlines()[1:]:
        m=re.search(r'(\d+)/\d+x(\d+)/\d+([+-]\d+)([+-]\d+)',line)
        if m:
            w,h,x,y=map(int,m.groups());result_rect.append((x,y,w,h))
    if not result_rect:
        g=root.get_geometry();result_rect=[(0,0,g.width,g.height)]
    return result_rect


def create(d,root,rectangles,radius=30):
    windows=[]
    for x,y,w,h in rectangles:
        r=min(radius,w//2,h//2)
        for right,bottom in [(False,False),(True,False),(False,True),(True,True)]:
            xx=x+w-r if right else x;yy=y+h-r if bottom else y
            win=root.create_window(xx,yy,r,r,0,X.CopyFromParent,X.InputOutput,X.CopyFromParent,
                background_pixel=d.screen().black_pixel,override_redirect=True)
            win.set_wm_class('bspwm-screen-corners','BspwmScreenCorners')
            win.change_property(d.intern_atom('_NET_WM_WINDOW_TYPE'),d.intern_atom('ATOM'),32,
                                [d.intern_atom('_NET_WM_WINDOW_TYPE_DOCK')])
            mask=root.create_pixmap(r,r,1)
            gc=mask.create_gc(foreground=0);mask.fill_rectangle(gc,0,0,r,r)
            gc.change(foreground=1)
            points=[]
            for py in range(r):
                for px in range(r):
                    dx=(px+.5) if right else (r-px-.5)
                    dy=(py+.5) if bottom else (r-py-.5)
                    if dx*dx+dy*dy > r*r:points.append((px,py))
            if points:mask.poly_point(gc,X.CoordModeOrigin,points)
            win.shape_mask(shape.SO.Set,shape.SK.Bounding,0,0,mask)
            gc.change(foreground=0);mask.fill_rectangle(gc,0,0,r,r)
            win.shape_mask(shape.SO.Set,shape.SK.Input,0,0,mask)
            win.map();win.configure(stack_mode=X.Above)
            gc.free();mask.free();windows.append(win)
    d.sync()
    return windows


def main():
    d=display.Display();root=d.screen().root
    old=None;windows=[]
    while True:
        rect=monitors(root)
        if rect!=old:
            for w in windows:w.destroy()
            windows=create(d,root,rect);old=rect
        for w in windows:w.configure(stack_mode=X.Above)
        d.flush();time.sleep(2)


if __name__=='__main__':main()
