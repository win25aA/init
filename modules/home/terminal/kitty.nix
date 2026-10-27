# kitty: терминал.
{ config, pkgs, inputs, ... }:

{
  programs.kitty = {
    enable = true;
    extraConfig = ''
      include matugen-colors.conf

      font_family      JetBrains Mono Nerd Font
      font_size 11.0

      cursor_shape beam
      cursor_trail 1
      remember_window_size no
      confirm_os_window_close 0
      hide_window_decorations yes
      window_border_width 0
      window_margin_width 0
      background_opacity 0.6
      background_blur 1

      shell fish

      map ctrl+c    copy_or_interrupt
      map ctrl+v    paste_from_clipboard

      map ctrl+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id
      map kitty_mod+f   launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id

      map page_up    scroll_page_up
      map page_down    scroll_page_down

      tab_bar_edge           bottom
      tab_bar_style          powerline
      tab_powerline_style    slanted
      tab_bar_min_tabs       1
      tab_title_template     "{title}"
      active_tab_font_style   bold

      # BEGIN_KITTY_THEME
      include current-theme.conf
      # END_KITTY_THEME
    '';
  };
}
