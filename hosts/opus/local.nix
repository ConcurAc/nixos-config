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
    "immich/api-keys/connor" = {
      owner = "immich-kiosk";
      group = "immich-kiosk";
    };

    "immich/api-keys/arete" = {
      owner = "immich-kiosk";
      group = "immich-kiosk";
    };

    "tandoor.env" = lib.mkIf config.services.tandoor-recipes.enable {
      owner = config.services.tandoor-recipes.user;
      group = config.services.tandoor-recipes.group;
    };

    "retrom.json" = lib.mkIf config.services.retrom.enable {
      sopsFile = ./retrom.json;
      format = "json";
      key = "";
      owner = "retrom";
      group = "retrom";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [
      7359 # jellyfin autodiscover
    ];
  };

  services = {
    home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        # Components required to complete the onboarding
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"

        "ipp"
        "nut"
        "home_connect"
        "homekit_controller"
        "brother"
        "izone"

        "wyoming"

        "jellyfin"
        "immich"
      ];
      config = {
        default_config = { };
        http = {
          server_host = "::1";
          trusted_proxies = [ "::1" ];
          use_x_forwarded_for = true;
        };
        template = {
          sensor = [
            {
              name = "Control zone";
              state = "{{ state_attr('climate.izone_controller_0000XXXXX','control_zone_name') }}";
            }
            {
              name = "Target temperature";
              state = "{{ state_attr('climate.izone_controller_0000XXXXX','control_zone_setpoint') }}";
              unit_of_measurement = "°C";
            }
            {
              name = "Supply temperature";
              state = "{{ state_attr('climate.izone_controller_0000XXXXX','supply_temperature') }}";
              unit_of_measurement = "°C";
            }
          ];
        };
      };
    };
    vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://passwords.opus.home.arpa";
        ENABLE_WEBSOCKET = true;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
      };
    };
    immich = {
      enable = true;
      accelerationDevices = [
        "/dev/dri/renderD128"
      ];
    };
    immich-kiosk = {
      enable = true;
      settings = {
        kiosk.port = 3030;
        immich_url = "https://photos.opus.home.arpa";
        immich_api_key._secret = secrets."immich/api-keys/arete".path;
        immich_users_api_keys = {
          arete._secret = secrets."immich/api-keys/arete".path;
        };
        show_videos = true;
        live_photos = true;
      };
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
    tandoor-recipes = {
      enable = true;
      database.createLocally = true;
      extraConfig = {
        MEDIA_ROOT = "/var/lib/tandoor-recipes/media";
        ALLOWED_HOSTS = "recipes.opus.home.arpa";
        AI_PROVIDER = "ollama";
      };
    };
    ollama = {
      enable = true;
      host = "0.0.0.0";
      package = pkgs.ollama-rocm;
      loadModels = [
        "qwen3:8b"
        "dolphin-mistral"
        "gemma3n"
        "translategemma:12b"
      ];
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

  users = {
    users.immich-kiosk = {
      isSystemUser = true;
      group = "immich-kiosk";
    };
    groups.immich-kiosk = { };
  };

  systemd.services = lib.mkIf config.services.tandoor-recipes.enable {
    tandoor-recipes.serviceConfig.EnvironmentFile = secrets."tandoor.env".path;
  };
}
