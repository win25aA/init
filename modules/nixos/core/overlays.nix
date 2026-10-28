# Оверлеи: SpotX, собственные пакеты и совместимость рекордера с NVIDIA 580.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.spotx-nix.overlays.default
    (final: prev: import ../../../pkgs { pkgs = final; })
    # Через prev избегаем рекурсии; GTK и Noctalia используют тот же backend.
    (final: prev: {
      gpu-screen-recorder = import ../../../pkgs/gpu-screen-recorder-nvidia580.nix {
        inherit (prev) gpu-screen-recorder ffmpeg_7;
      };
    })
  ];
}
