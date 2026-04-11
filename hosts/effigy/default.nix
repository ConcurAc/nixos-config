{
  resources,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disks.nix
    ./system.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
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

  boot.plymouth.enable = true;

  security = {
    pki.certificates = [
      (builtins.readFile resources.ca.cert.root)
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

  fileSystems = {
    "/srv/library" = {
      device = "opus.home.arpa:/library";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/users" = {
      device = "opus.home.arpa:/users";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/media" = {
      device = "opus.home.arpa:/media";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "opus.home.arpa:/archives";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/games" = {
      device = "opus.home.arpa:/games";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/steam" = {
      device = "opus.home.arpa:/steam";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
  };

  networking = {
    hostName = "effigy";
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
    };
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
    xserver.videoDrivers = [
      "nvidia"
      "intel"
    ];
    udisks2.enable = true;
    upower.enable = true;
    pipewire = {
      enable = true;
      jack.enable = true;
    };
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
    gvfs.enable = true;
    power-profiles-daemon.enable = true;
    clamav = {
      daemon.enable = true;
      scanner.enable = true;
      updater.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    waypipe
  ];

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
