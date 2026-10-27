# SoundCloud Desktop (AppImage).
{ appimageTools, fetchurl }:

appimageTools.wrapType2 {
  pname = "soundcloud-desktop";
  version = "8.4.13";
  src = fetchurl {
    url = "https://github.com/zxcloli666/SoundCloud-Desktop-EN/releases/download/8.4.13/soundcloud-desktop_8.4.13_amd64.AppImage";
    hash = "sha256-yM5BD/VYkhEHBD3tkvC7xbrsUup+olaD5Q8tuOjcKEc=";
  };
}
