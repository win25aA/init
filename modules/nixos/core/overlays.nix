# Оверлеи: SpotX + собственные пакеты из ./pkgs.
{ config, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.spotx-nix.overlays.default
    (final: prev: import ../../../pkgs { pkgs = final; })
  ]
  # gpu-screen-recorder, собранный под драйвер NVIDIA 580, нужен только с NVIDIA.
  ++ lib.optional (config.my.gpu == "nvidia") (final: prev: {
    gpu-screen-recorder = import ../../../pkgs/gpu-screen-recorder-nvidia580.nix {
      inherit (prev) gpu-screen-recorder ffmpeg_7;
    };
  });
}
