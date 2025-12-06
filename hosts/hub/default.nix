{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
in
{
  imports = [
    ./system.nix
    ./disks.nix
    ./services.nix
    ../../modules/user-containers.nix
  ];

  boot.plymouth.enable = true;

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets = {
      root-passwd = {
        sopsFile = ./secrets.yaml;
        neededForUsers = true;
      };
    };
  };
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  users.users.root.hashedPasswordFile = secrets.root-passwd.path;

  fileSystems = {
    "/mnt/users" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@users"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/mnt/media" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@media"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/mnt/gallery" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@gallery"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/mnt/archives" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@archives"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/mnt/games" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@games"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/mnt/steam" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=15s"
        "subvol=@steam"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
  };

  networking = {
    hostName = "hub";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    useDHCP = lib.mkDefault true;
    interfaces.enp7s0.wakeOnLan.enable = true;
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = lib.getExe pkgs.tuigreet;
        };
      };
    };
    gvfs.enable = true;
    udisks2.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  programs = {
    nix-ld.enable = true;
    steam.enable = true;
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      waypipe
      cage
    ]
    ++ (with rocmPackages; [
      rocm-core
    ]);

  security = {
    pam.mount = {
      enable = true;
      createMountPoints = true;
      removeCreatedMountPoints = true;
      fuseMountOptions = [
        "nodev"
        "nosuid"
      ];
      additionalSearchPaths = with pkgs; [
        gocryptfs
      ];
    };
  };

  stylix = {
    enable = true;
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/hopscotch.yaml";
  };

  user-containers = {
    enable = true;
    withGPU = true;
    interface =  }
    ];
  };
}
