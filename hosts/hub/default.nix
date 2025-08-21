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
    ]);

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sr_mod"
    ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" ];

    loader = {
      grub = {
        device = "nodev";
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };

    tmp.useZram = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1cf0b225-6bee-411d-a7c2-54af812b0e99";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/1cf0b225-6bee-411d-a7c2-54af812b0e99";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/1cf0b225-6bee-411d-a7c2-54af812b0e99";
    fsType = "btrfs";
    options = [ "compress=zstd,subvol=@nix" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2949-9621";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  zramSwap.enable = true;

  networking = {
    hostName = "hub";
    networkmanager.enable = true;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.containers = {
      invoke-ai = {
        image = "ghcr.io/invoke-ai/invokeai";
        hostname = "models.invoke.ai";
        ports = [
          "127.0.0.1:9090:9090"
        ];
        volumes = [
          "invoke-ai:/invokeai"
        ];
        extraOptions = [
          "--gpus=all"
        ];
      };
    };
  };
}
