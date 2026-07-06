{ config, pkgs, inputs, ... }:

{
  home.file."Pictures/wallpapers" = {
    source = ../wallpapers;
    recursive = true;
  };
}
