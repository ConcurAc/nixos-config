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
      common-gpu-nvidia
      common-pc-laptop
      common-pc-ssd
    ])
    ++ [
      ./disks.nix
    ];

  boot = {
    plymouth.enable = true;
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

  fileSystems = {
    "/srv/library" = {
      device = "opus.home.arpa:/library";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/users" = {
      device = "opus.home.arpa:/users";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "opus.home.arpa:/archives";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/games" = {
      device = "opus.home.arpa:/games";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/steam" = {
      device = "opus.home.arpa:/steam";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
  };

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets = {
      home = {
        sopsFile = ./home.conf;
        format = "binary";
      };
      proxy = {
        sopsFile = ./proxy.conf;
        format = "binary";
      };
    };
  };

  security = {
    pki.certificates = [
      ''
        -----BEGIN CERTIFICATE-----
        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
        PK+w4Po=
        -----END CERTIFICATE-----
      ''
    ];
    pam.mount = {
      enable = true;
      createMountPoints = true;
      fuseMountOptions = [
        "nodev"
        "nosuid"
      ];
      additionalSearchPaths = with pkgs; [
        gocryptfs
        mergerfs
      ];
    };
  };

  networking = {
    hostName = "effigy";
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
    };
    useDHCP = lib.mkDefault true;
    wg-quick.interfaces = {
      home = {
        autostart = false;
        configFile = config.sops.secrets.home.path;
      };
      proxy = {
        autostart = false;
        configFile = config.sops.secrets.proxy.path;
      };
    };
  };

  programs = {
    gnupg.agent.enable = true;
    nix-ld.enable = true;
    gamemode.enable = true;
    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
  };

  services = {
    greetd = {
      enable = true;
      useTextGreeter = true;
      greeterManagesPlymouth = true;
      settings = {
        default_session = {
          command = lib.getExe pkgs.tuigreet;
        };
      };
    };
    xserver.videoDrivers = [
      "nvidia"
      "intel"
    ];
    pipewire = {
      enable = true;
      jack.enable = true;
    };
    udisks2.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
    waypipe
  ];

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

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
    enableDefaultPackages = true;
  };

  stylix = {
    enable = true;
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
}
