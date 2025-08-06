{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports =
    with inputs;
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      disko.nixosModules.disko
    ]
    ++ (with nixos-hardware.nixosModules; [
      common-cpu-intel
      common-pc
      common-pc-ssd
    ]) ++ [
      ./disko-config.nix
    ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" ];

    loader = {
      grub = {
        efiSupport = true;
        device = "nodev";
      };
      efi.canTouchEfiVariables = true;
    };

    tmp.useZram = true;
  };

  zramSwap.enable = true;

  networking = {
    hostName = "slave";
    networkmanager.enable = true;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
