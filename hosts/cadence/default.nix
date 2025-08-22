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
      sops-nix.nixosModules.sops
    ]
    ++ (with nixos-hardware.nixosModules; [
      common-cpu-intel
      common-pc
      common-pc-ssd
    ]);

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets = {
      passwd.neededForUsers = true;
      deluge-auth = {
        owner = "deluge";
        group = "deluge";
      };
      proxy = {
        format = "binary";
        sopsFile = ./proxy.conf;
      };
    };
  };

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
    supportedFilesystems = [ "nfs" ];

    loader = {
      grub = {
        device = "nodev";
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };

    tmp.useZram = true;
  };

  disko.devices = {
    disk = {
      eMMC = {
        device = "/dev/mmcblk0";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
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
                type = "filesystem";
                mountpoint = "/";
                format = "f2fs";
                extraArgs = [
                  "-O"
                  "extra_attr,inode_checksum,sb_checksum,compression"
                ];
                mountOptions = [
                  "compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime,nodiscard"
                ];
              };
            };
          };
        };
      };
    };
  };

  systemd = {
    mounts = [
      {
        type = "nfs";
        what = "server:/archives";
        where = "/mnt/archives";
      }
      {
        type = "nfs";
        what = "server:/media";
        where = "/mnt/media";
      }
    ];

    automounts = [
      {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/archives";
      }
      {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/media";
      }
    ];
    services.rqbit = {
      description = "starts rqbit server";
      script = ''
        ${pkgs.rqbit}/bin/rqbit server start /mnt/archives
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };

  environment.systemPackages = with pkgs; [
    rqbit
  ];

  networking = {
    hostName = "cadence";
    networkmanager.enable = true;
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    firewall.allowedUCPPorts = [ 3030 ];
  };

  services = {
    openvpn.servers.proxy.config = "config ${config.sops.secrets.proxy.path}";
    deluge = {
      enable = true;
      declarative = true;
      authFile = config.sops.secrets.deluge-auth.path;
      openFirewall = true;
      web = {
        enable = true;
        openFirewall = true;
      };
    };
  };

  zramSwap.enable = true;

  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = config.sops.secrets.passwd.path;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
