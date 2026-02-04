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
  sops.secrets = {
    "stalwart/admin_secret" = lib.mkIf config.services.stalwart-mail.enable {
      owner = "stalwart-mail";
      group = "stalwart-mail";
    };

    "retrom.json" = lib.mkIf config.services.retrom.enable {
      sopsFile = ./retrom.json;
      format = "json";
      key = "";
      owner = "retrom";
      group = "retrom";
    };
  };

  fileSystems = {
    "/srv/library" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@library"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/library" = {
      device = "/srv/library";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/users" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@users"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/users" = {
      device = "/srv/users";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/media" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@media"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/media" = {
      device = "/srv/media";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/gallery" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@gallery"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@archives"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/archives" = {
      device = "/srv/archives";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/crypto" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@crypto"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/games" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@games"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/games" = {
      device = "/srv/games";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/steam" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@steam"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/steam" = {
      device = "/srv/steam";
      options = [
        "bind"
        "nofail"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    2049 # nfs
  ];

  services = {
    nfs.server = {
      enable = true;
      exports = ''
        /exports 192.168.1.0/24(rw,crossmnt,fsid=0)
        /exports/library 192.168.1.0/24(rw,insecure)
        /exports/users 192.168.1.0/24(rw,insecure)
        /exports/media 192.168.1.0/24(rw,insecure)
        /exports/gallery 192.168.1.0/24(rw,insecure)
        /exports/archives 192.168.1.0/24(rw,insecure)
        /exports/steam 192.168.1.0/24(rw,insecure)
        /exports/games 192.168.1.0/24(rw,insecure)
      '';
    };
    ollama = {
      enable = false;
      package = pkgs.ollama-rocm;
      loadModels = [
        "qwen3:8b"
        "gemma3:270m"
        "gemma3:4b"
        "deepseek-r1:8b"
      ];
    };
    polaris.enable = true;
    vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://passwords.scequ.com";
        ENABLE_WEBSOCKET = true;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
      };
    };
    immich = {
      enable = true;
    };
    jellyfin = {
      enable = true;
      hardwareAcceleration = {
        enable = true;
        type = "vaapi";
        device = "/dev/dri/renderD128";
      };
      transcoding = {
        enableHardwareEncoding = true;
      };
    };
    stalwart-mail = {
      enable = true;
      openFirewall = true;
      settings = {
        server.listener = {
          smtp = {
            bind = [ "[::]:25" ];
            protocol = "smtp";
          };
          submissions = {
            bind = [ "[::]:465" ];
            protocol = "smtp";
            tls.implicit = true;
          };
          imaptls = {
            bind = [ "[::]:993" ];
            protocol = "imap";
            tls.implicit = true;
          };
          http = {
            bind = [ "[::]:7999" ];
            protocol = "http";
          };
        };
        http = {
          use-x-forwarded = true;
        };
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${secrets."stalwart/admin_secret".path}}%";
        };
      };
    };
    minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;
      servers = {
        vanilla = {
          enable = true;
          package = pkgs.minecraft-server;
          autoStart = false;
          jvmOpts = "-Xms2048M -Xmx4096M";
          serverProperties = {
            online-mode = false;
            server-port = 25565;
            difficulty = 3;
            gamemode = 0;
            max-players = 5;
            motd = "NixOS Minecraft server!";
          };
        };
        paper = {
          enable = true;
          package = pkgs.papermc;
          autoStart = false;
          jvmOpts = "-Xms2048M -Xmx4096M";
          serverProperties = {
            online-mode = false;
            server-port = 25566;
            difficulty = 3;
            gamemode = 0;
            max-players = 5;
            motd = "NixOS Paper server!";
          };
        };
      };
    };
    retrom = {
      enable = true;
      enableDatabase = true;
      configFile = secrets."retrom.json".path;
    };
  };
}
