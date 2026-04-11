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

    "searx.env" = lib.mkIf config.services.searx.enable {
      owner = "searx";
      group = "searx";
    };

    "retrom.json" = lib.mkIf config.services.retrom.enable {
      owner = config.services.retrom.user;
      group = config.services.retrom.group;
    };

    "monero.env" = lib.mkIf config.services.monero.enable {
      owner = "monero";
      group = "monero";
    };

    "pki/monero.key" = lib.mkIf config.services.monero.enable {
      key = "pki/self.key";
      owner = "monero";
      group = "monero";
    };

    "pki/monero.crt" = lib.mkIf config.services.monero.enable {
      key = "pki/self.crt";
      owner = "monero";
      group = "monero";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      18080 # monero
      config.services.monero.rpc.port
    ];
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
      };
    };
    vaultwarden = {
      enable = true;
      configureNginx = true;
      domain = "passwords.home.arpa";
      config = {
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
        immich_url = "https://photos.home.arpa";
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
        ALLOWED_HOSTS = "recipes.home.arpa";
      };
    };
    searx = {
      enable = true;
      environmentFile = secrets."searx.env".path;

      configureNginx = true;
      redisCreateLocally = true;

      domain = "search.home.arpa";

      uwsgiConfig = {
        disable-logging = true;
      };
      faviconsSettings = {
        favicons = {
          cfg_schema = 1;
          cache = {
            db_url = "/var/cache/searx/faviconcache.db";
            HOLD_TIME = 7 * 24 * 60 * 60; # cache for a week
            LIMIT_TOTAL_BYTES = 268435456;
            BLOB_MAX_BYTES = 40960;
            MAINTENANCE_MODE = "auto";
            MAINTENANCE_PERIOD = 600;
          };
        };
      };

      settings = {
        server = {
          secret_key = "$SEARX_SECRET_KEY";
        };
        search = {
          formats = [
            "html"
            "json"
          ];

          max_results = 5;
          timeout = 2;

          cache = lib.mkIf config.services.searx.redisCreateLocally {
            enabled = true;
            type = "redis";
            ttl = 7 * 24 * 60 * 60; # cache for a week
            url = "unix://${config.services.redis.servers.searx.unixSocket}";
          };
        };
      };
    };
    llama-swap = {
      enable = true;
      port = 11343;
      settings =
        let
          port = "\${PORT}";
          server = "${lib.getExe' pkgs.llama-cpp-rocm "llama-server"} --port ${port} --jinja --no-webui --offline";
          env = [
            "LLAMA_CACHE=/srv/ai/huggingface/hub"
          ];
        in
        {
          healthCheckTimeout = 60;
          models = {
            "qwen3.5-9b-uncensored" = {
              inherit env;
              cmd = "${server} -hf HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive:Q8_0 -c 128000";
              checkEndpoint = "none"; # don't timeout download
            };
            "gemma-4-e4b-uncensored" = {
              inherit env;
              cmd = "${server} -hf HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive:Q5_K_M -c 128000";
              checkEndpoint = "none"; # don't timeout download
            };
          };
        };
    };
    open-webui = {
      enable = true;
      port = 8060;
    };
    monero = {
      enable = true;
      prune = true;

      environmentFile = secrets."monero.env".path;
      dataDir = "/srv/crypto/monero";
      rpc = {
        user = "$MONERO_USER";
        password = "$MONERO_PASSWORD";
        address = "127.0.0.1";
      };
      priorityNodes = [
        "p2pmd.xmrvsbeast.com:18080"
        "nodes.hashvault.pro:18080"
      ];
      extraConfig = ''
        zmq-pub=tcp://0.0.0.0:18083

        # peers
        out-peers=32
        in-peers=64

        # dns
        enforce-dns-checkpointing=1
        enable-dns-blocklist=1

        # ssl
        rpc-ssl-private-key=${secrets."pki/monero.key".path}
        rpc-ssl-certificate=${secrets."pki/monero.crt".path}
      '';
    };

    hermes-agent = {
      enable = true;
      settings = {
        model = {
          default = "gemma-4-e4b-uncensored";
          base_url = "https://llama.home.arpa/v1";
        };
        display = {
          compact = true;
          personality = "kawaii";
        };
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
      };
      addToSystemPackages = true;
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

  systemd.services = {
    tandoor-recipes = lib.mkIf config.services.tandoor-recipes.enable {
      serviceConfig.EnvironmentFile = secrets."tandoor.env".path;
    };
    llama-swap.serviceConfig.BindPaths = [
      "/srv/ai/huggingface"
    ];
  };
}
