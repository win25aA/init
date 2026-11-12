# Шрифты, используемые интерфейсом ii.
{ stdenvNoCC, fetchurl }:
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-fonts";
  version = "2026-ii";
  dontUnpack = true;
  google = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/2e5fa2e951237b6ae65f705693d12ca76a7f78c8/ofl/googlesansflex/GoogleSansFlex%5BROND,opsz,slnt,wdth,wght%5D.ttf";
    hash = "sha256-qax3B5iFfV6KxZPO1Csi5Ap8CM7Jgxn5Kw7Mwng6d7o=";
  };
  readex = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/2e5fa2e951237b6ae65f705693d12ca76a7f78c8/ofl/readexpro/ReadexPro%5BHEXP,wght%5D.ttf";
    hash = "sha256-Jou6fh6POxTXmLP7DkDrqj/DkwjJrAAg4vr23xgcww4=";
  };
  space = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/2e5fa2e951237b6ae65f705693d12ca76a7f78c8/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf";
    hash = "sha256-rK1t4fyTQ29cDx9BN3Ue8E8a6jBj5wNlNZcP/PvXn3I=";
  };
  installPhase = ''
    mkdir -p "$out/share/fonts/truetype"
    cp "$google" "$out/share/fonts/truetype/GoogleSansFlex.ttf"
    cp "$readex" "$out/share/fonts/truetype/ReadexPro.ttf"
    cp "$space" "$out/share/fonts/truetype/SpaceGrotesk.ttf"
  '';
}
