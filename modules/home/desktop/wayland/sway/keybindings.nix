# Sway: горячие клавиши.
{ ... }:

let
  mod = "Mod4";
  ipc = "noctalia msg";
  digits = [ 1 2 3 4 5 6 7 8 9 ];

  bindWorkspaces = builtins.listToAttrs (map (n: {
    name = "${mod}+${toString n}";
    value = "workspace number ${toString n}";
  }) digits);

  bindMove = builtins.listToAttrs (map (n: {
    name = "${mod}+Ctrl+${toString n}";
    value = "move container to workspace number ${toString n}; workspace number ${toString n}";
  }) digits);
in
{
  wayland.windowManager.sway.config = {
    keybindings =
      bindWorkspaces
      // bindMove
      // {
        "${mod}+0" = "workspace number 10";
        "${mod}+Ctrl+0" = "move container to workspace number 10; workspace number 10";

        "--whole-window ${mod}+button4" = "workspace next_on_output";
        "--whole-window ${mod}+button5" = "workspace prev_on_output";

        "${mod}+Left" = "focus left";
        "${mod}+Right" = "focus right";
        "${mod}+Up" = "focus up";
        "${mod}+Down" = "focus down";

        "--to-code ${mod}+f" = "fullscreen toggle";
        "--to-code ${mod}+q" = "kill";
        "--to-code ${mod}+v" = "floating toggle";
        "--to-code ${mod}+m" = "exit";
        "--to-code ${mod}+Shift+c" = "reload";

        "${mod}+space" = "exec ${ipc} panel-toggle launcher";
        "--to-code ${mod}+Shift+w" = "exec ${ipc} panel-toggle wallpaper";
        "--to-code ${mod}+p" = "exec ${ipc} panel-toggle session";
        "--to-code ${mod}+z" = "exec ${ipc} panel-toggle control-center";
        "--to-code ${mod}+Shift+z" = "exec ${ipc} panel-toggle nilsonlinux/world-radio:Panel";
        "--to-code ${mod}+Shift+s" = "exec ${ipc} screenshot-fullscreen";
        "--to-code ${mod}+Ctrl+s" = "exec ${ipc} screenshot-region";

        "--whole-window ${mod}+BTN_SIDE" = "exec playerctl previous";
        "--whole-window ${mod}+BTN_EXTRA" = "exec playerctl next";

        "--to-code ${mod}+a" = "exec kitty";
        "--to-code ${mod}+e" = "exec thunar";
        "--to-code ${mod}+w" = "exec firefox";
        "--to-code ${mod}+t" = "exec AyuGram";
        "--to-code ${mod}+s" = "exec steam";

        "--to-code ${mod}+d" = "exec vesktop";
        "--to-code ${mod}+c" = "exec spotify";
      };
  };
}
