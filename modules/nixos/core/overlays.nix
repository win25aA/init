# Оверлеи: SpotX + собственные пакеты из ./pkgs.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.spotx-nix.overlays.default
    (final: prev: import ../../../pkgs { pkgs = final; })
  ];
}
