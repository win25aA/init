# Spotify (SpotX), который в X11 сам переключается на ozone-platform=x11.
{ symlinkJoin, makeWrapper, spotify-spotx }:

symlinkJoin {
  name = "spotify-session";
  paths = [ spotify-spotx ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/spotify" --run '
      if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        unset NIXOS_OZONE_WL WAYLAND_DISPLAY
        set -- --ozone-platform=x11 "$@"
      fi
    '

    desktop="$out/share/applications/spotify.desktop"
    if [ -e "$desktop" ]; then
      cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
      sed -i -E "s|^Exec=[^ ]+|Exec=$out/bin/spotify|; s|^TryExec=.*|TryExec=$out/bin/spotify|" "$desktop"
    fi
  '';
}
