{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-nvidia
    common-pc-laptop
    common-pc-ssd
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "sdhci_pci"
      ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules =
      if (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.1") then
        [
          "kvm-intel"
          "hp-wmi"
        ]
      else
        [
          "kvm-intel"
        ];
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

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      powerManagement = {
        enable = true;
        finegrained = true;
      };
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  zramSwap.enable = true;
}
