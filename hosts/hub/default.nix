{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./system.nix
    ./disks.nix
    ../../modules/container-services
  ];

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets.root-passwd = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.root-passwd.path;

  networking = {
    hostName = "hub";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    useDHCP = lib.mkDefault true;
    interfaces.enp7s0.wakeOnLan.enable = true;
    firewall.allowedTCPPorts = [
      80 # http
      443 # https
      2049 # nfs
    ];
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
    nfs.server = {
      enable = true;
      exports = ''
        /export 192.168.1.0/24(rw,crossmnt,fsid=0)
        /export/users 192.168.1.0/24(rw,insecure)
      '';
    };
    avahi = {
      enable = true;
      openFirewall = true;
    };
    udisks2.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    ollama = {
      enable = true;
      openFirewall = true;
      host = "0.0.0.0";
      acceleration = "rocm";
      loadModels = [
        "qwen3:8b"
        "gemma3:270m"
        "gemma3:4b"
        "deepseek-r1:8b"
      ];
    };
    vaultwarden.enable = true;
    immich = {
      enable = true;
      openFirewall = true;
      host = "0.0.0.0";
    };
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "invoke-ai" = {
          locations."/" = {
            proxyPass = "http://localhost:9090";
          };
        };
        "jellyfin" = {
          locations."/" = {
            proxyPass = "http://localhost:8096";
          };
        };
      };
    };
  };

  programs = {
    virt-manager = {
      enable = true;
    };
    steam.enable = true;
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
  };

  environment.systemPackages = with pkgs.rocmPackages; [
    rocm-core
  ];

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
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  };

  container-services = {
    enable = true;
    withGPU = true;
    interface = "enp7s0";
    services = {
      invoke-ai = {
        enable = true;
        openFirewall = true;
        withGPU = true;
        host = "0.0.0.0";
      };
    };
  };
}
