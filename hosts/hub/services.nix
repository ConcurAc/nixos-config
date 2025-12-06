{ config, ... }:
let
  secrets = config.sops.secrets;
in
{
  imports = [
    ../../modules/services/invoke-ai.nix
  ];

  sops.secrets = {
    "retrom.json" = {
      sopsFile = ./retrom.json;
      format = "json";
      key = "";
      owner = "retrom";
      group = "retrom";
    };
  };

  fileSystems = {
    "/exports/users" = {
      device = "/mnt/users";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/exports/media" = {
      device = "/mnt/users";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/exports/gallery" = {
      device = "/mnt/users";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/exports/archives" = {
      device = "/mnt/archives";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/exports/games" = {
      device = "/mnt/games";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/exports/steam" = {
      device = "/mnt/steam";
      options = [
        "bind"
        "nofail"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
    2049 # nfs
  ];

  services = {
    nfs.server = {
      enable = true;
      exports = ''
        /exports 192.168.1.0/24(rw,crossmnt,fsid=0)
        /exports/users 192.168.1.0/24(rw,insecure)
        /exports/media 192.168.1.0/24(rw,insecure)
        /exports/gallery 192.168.1.0/24(rw,insecure)
        /exports/archives 192.168.1.0/24(rw,insecure)
        /exports/games 192.168.1.0/24(rw,insecure)
        /exports/steam 192.168.1.0/24(rw,insecure)
      '';
    };
    ollama = {
      enable = true;
      acceleration = "rocm";
      loadModels = [
        "qwen3:8b"
        "gemma3:270m"
        "gemma3:4b"
        "deepseek-r1:8b"
      ];
    };
    polaris.enable = true;
    vaultwarden.enable = true;
    immich.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "100m";
      virtualHosts = {
        "ollama.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.ollama.port}";
          };
        };

        "immich.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.immich.port}";
            proxyWebsockets = true;
          };
        };

        "jellyfin.local" = {
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8096";
              recommendedProxySettings = false;
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host $http_host;
                proxy_buffering off;
              '';
            };
            "/socket" = {
              proxyPass = "http://127.0.0.1:8096";
              proxyWebsockets = true;
              recommendedProxySettings = false;
              extraConfig = ''
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host $http_host;
              '';
            };
          };
          extraConfig = ''
            # Security / XSS Mitigation Headers
            add_header X-Content-Type-Options "nosniff";

            # Permissions policy. May cause issues with some clients
            add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;

            # Content Security Policy
            # See: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
            # Enforces https content and restricts JS/CSS to origin
            # External Javascript (such as cast_sender.js for Chromecast) must be whitelisted.
            add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";
          '';
        };

        "polaris.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.polaris.port}";
          };
        };

        "vaultwarden.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
          };
        };

        "invoke-ai.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.invoke-ai.port}";
          };
        };

        "retrom.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.retrom.port}";
          };
        };
      };
    };

    # custom modules config
    invoke-ai = {
      enable = true;
      openFirewall = true;
      withGPU = true;
    };
    retrom = {
      enable = true;
      enableDatabase = true;
      configFile = secrets."retrom.json".path;
    };
  };
}
