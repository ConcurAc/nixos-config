{ config, pkgs, ... }:
let
  cfg = config.users.users.connor;
  cfgPhotoPrism = config.services.photoprism;
  cfgTrilium = config.services.trilium-server;
  secrets = config.sops.secrets;
in
{
  sops = {
    secrets = {
      syncthing-passwd = {
        sopsFile = ./secrets.yaml;
        owner = cfg.name;
        group = cfg.name;
      };
      photoprism-passwd = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };
      "livebook.env" = {
        sopsFile = ./livebook.env;
        format = "dotenv";
        key = "";
        owner = cfg.name;
        group = cfg.group;
      };
    };
  };

  networking = {
    firewall.allowedTCPPorts = [
      80
      443
    ];
  };

  console.enable = true;
  services = {
    openssh.enable = true;
    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "connor";
      guiPasswordFile = secrets.syncthing-passwd.path;
    };
    photoprism = {
      enable = true;
      originalsPath = "${cfg.home}/gallery";
      settings = {
        PHOTOPRISM_ADMIN_USER = "connor";
        PHOTOPRISM_ADMIN_PASSWORD_FILE = secrets.photoprism-passwd.path;
        PHOTOPRISM_DATABASE_PASSWORD = secrets.photoprism-passwd.path;
      };
    };
    trilium-server = {
      enable = true;
    };
    livebook = {
      enableUserService = true;
      environment = {
        LIVEBOOK_PORT = 8080;
      };
      environmentFile = secrets."livebook.env".path;
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "photoprism.connor.me" = {
          locations."/" = {
            proxyPass = "http://${cfgPhotoPrism.address}:${toString cfgPhotoPrism.port}";
            proxyWebsockets = true;
          };
        };
        "syncthing.connor.me" = {
          locations."/" = {
            proxyPass = "http://${config.services.syncthing.guiAddress}";
          };
        };
        "trilium.connor.me" = {
          locations."/" = {
            proxyPass = "http://${cfgTrilium.host}:${toString cfgTrilium.port}";
            proxyWebsockets = true;
          };
        };
        "livebook.connor.me" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.livebook.environment.LIVEBOOK_PORT}";
          };
        };
      };
    };
  };
}
