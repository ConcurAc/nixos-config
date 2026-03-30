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
    ./local.nix
    ./proxy.nix
    ./exports.nix
    ./scequ.com
    ../../modules/user-containers.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
  };

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      root-passwd = {
        neededForUsers = true;
      };
    };
  };

  users.users.root.hashedPasswordFile = secrets.root-passwd.path;

  boot.plymouth.enable = true;

  hardware = {
    steam-hardware.enable = true;
  };

  security = {
    pki.certificates = [
      (builtins.readFile ./self.crt)
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
    hostName = "opus";
    useDHCP = lib.mkDefault true;
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

  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in
    [
      "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    ];

  environment.systemPackages = with pkgs; [
    waypipe
    xwayland-run
  ];

  programs = {
    nix-ld.enable = true;
    steam.enable = true;
    gamemode.enable = true;
  };

  services = {
    desktopManager = {
      cosmic = {
        enable = true;
        xwayland.enable = true;
      };
    };
    displayManager.cosmic-greeter.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  stylix = {
    enable = true;
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/hopscotch.yaml";
  };

  user-containers = {
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
}
