{
  assets,
  modules,
  config,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
in
{
  imports = with modules; [
    defaults
    setup
    features
    user-containers

    ./secrets
    ./system.nix
    ./disks.nix
    ./exports.nix
    ./ca
    ./services
    ./scequ.com
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      extra-substituters = [
        "https://comfyui.cachix.org"
        "https://nix-community.cachix.org"
        "https://retrom.cachix.org"
      ];
      extra-trusted-public-keys = [
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "retrom.cachix.org-1:6fjezFeBSDzHkUvpyLMe58wfi99V4RO8M5Iod4sMxFE="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
  };

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  setup = {
    terminal.enable = true;
    desktop = {
      enable = true;
      polkit = true;
    };
    fonts = {
      enable = true;
      emoji = true;
      cjk = true;
      lgc = true;
    };
  };

  boot.plymouth.enable = true;

  users = {
    users.root.hashedPasswordFile = secrets."passwd".path;
    groups.games = { };
    files = {
      enable = true;
      useFuse = true;
      overlays.games = {
        enable = true;
        group = "games";
      };
    };

    containers = {
      enable = true;
      interface = "br-vlan100";
      withGPU = true;
      allowedDevices = [
        {
          node = "/dev/dri/renderD128";
          modifier = "rw";
        }
        {
          node = "/dev/dri/renderD129";
          modifier = "rw";
        }
      ];
    };
  };

  security = {
    sudo-rs.enable = true;
    pki.certificates = [
      (builtins.readFile assets.ca.root)
    ];
  };

  networking = {
    hostName = "opus";
    vlans = {
      vlan100 = {
        id = 100;
        interface = "enp7s0";
      };
      vlan1100 = {
        id = 1100;
        interface = "enp7s0";
      };
    };
    bridges = {
      br-vlan100 = {
        interfaces = [ "vlan100" ];
      };
      br-vlan1100 = {
        interfaces = [ "vlan1100" ];
      };
    };
    interfaces.enp7s0 = {
      wakeOnLan.enable = true;
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      waypipe
      xwayland-run
    ];
  };

  programs = {
    nix-ld.enable = true;
  };

  services = {
    kanidm = {
      package = pkgs.kanidm_1_10;
      client = {
        enable = true;
        settings.uri = "https://id.home.arpa";
      };

      unix = {
        enable = true;
        settings = {
          kanidm.pam_allowed_login_groups = [ "users" ];
          sshIntegration = true;
        };
      };
    };

    #     xwayland.enable = true;
    #   };
    # };
    openssh.enable = true;
    displayManager.cosmic-greeter.enable = true;
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
      qemu = {
        swtpm.enable = true;
        runAsRoot = false;
      };
    };
  };

  stylix = {
    enable = true;
    base16Scheme = assets.palette.hephae-soft;
  };

  system.stateVersion = "25.05";
}
