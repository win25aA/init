# polkit, pkexec, doas.
{ pkgs, ... }:

{
  security.polkit.enable = true;

  security.wrappers.pkexec = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.polkit.bin}/bin/pkexec";
  };

  environment.systemPackages = with pkgs; [
    doas
  ];
}
