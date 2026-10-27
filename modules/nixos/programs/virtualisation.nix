# Виртуальные машины: libvirt + virt-manager.
{ ... }:

{
  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;
}
