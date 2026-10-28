# Оверлеи: SpotX + собственные пакеты из ./pkgs.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.spotx-nix.overlays.default
    (final: prev: import ../../../pkgs { pkgs = final; })
    (final: prev: {
      gpu-screen-recorder = import ../../../pkgs/gpu-screen-recorder-nvidia580.nix {
        inherit (prev) gpu-screen-recorder ffmpeg_7;
      };
    })
  ];
}
