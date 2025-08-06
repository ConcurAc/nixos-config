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

  disko.devices = {
    disk = {
      internal = {
        device = "/dev/mmcblk0";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              type = "EF00";
              start = "1M";
              end = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/@" = {
                    mountpoint = "/";
                  };
                  "/@home" = {
                    mountpoint = "/home";
                  };
                  "/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
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
