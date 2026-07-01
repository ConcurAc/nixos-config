{
  assets,
  modules,
  config,
  ...
}:
let
  secrets = config.sops.secrets;
in
{
  imports = with modules; [
    defaults
    setup

    ./secrets
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
      (builtins.readFile assets.ca.root)
    ];
  };

  users.users.root.hashedPasswordFile = secrets."passwd".path;

  networking = {
    hostName = "effigy";
    wg-quick.interfaces = {
      home = {
        autostart = false;
        configFile = secrets."wg-home".path;
      };
      proxy = {
        autostart = false;
        configFile = secrets."wg-proxy".path;
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
    sunshine = {
      enable = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };

  stylix = {
    enable = true;
    base16Scheme = assets.palette.hephae-soft;
  };

  system.stateVersion = "25.05";
}
