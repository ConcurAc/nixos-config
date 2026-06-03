{
  resources,
  modules,
  config,
  ...
}:
let
  secret = secret: config.sops.secrets."hosts/effigy/${secret}".path;
in
{
  imports = with modules; [
    defaults
    secrets
    setup

    ./disks.nix
    ./system.nix
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  setup = {
    terminal.enable = true;
    login.enable = true;
    desktop = {
      enable = true;
      polkit = true;
      printing = true;
    };
    fonts = {
      enable = true;
      emoji = true;
      cjk = true;
      lgc = true;
    };
  };

  security = {
    sudo-rs.enable = true;
    pki.certificates = [
      (builtins.readFile resources.ca.root)
    ];
  };

  users.users.root.hashedPasswordFile = secret "passwd";

  networking = {
    hostName = "effigy";
    wg-quick.interfaces = {
      home = {
        autostart = false;
        configFile = secret "wg-home";
      };
      proxy = {
        autostart = false;
        configFile = secret "wg-proxy";
      };
    };
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
    };
  };

  programs = {
    nix-ld.enable = true;
  };

  services = {
    openssh.enable = true;
    power-profiles-daemon.enable = true;
  };

  stylix.enable = true;

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

  system.stateVersion = "25.05";
}
