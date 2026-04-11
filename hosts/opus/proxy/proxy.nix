{ config, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      server = "https://ca.home.arpa/acme/acme/directory";
      email = "acme@scequ.com";
      validMinDays = 1;
      renewInterval = "hourly";
      group = "nginx";
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    upstreams = {
      home-assistant.servers."localhost:${toString config.services.home-assistant.config.http.server_port}" =
        { };
      vaultwarden.servers."localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}" = { };
      jellyfin.servers."localhost:8096" = { };
      immich.servers."localhost:${toString config.services.immich.port}" = { };
      immich-kiosk.servers."localhost:${toString config.services.immich-kiosk.settings.kiosk.port}" = { };
      tandoor.servers."localhost:${toString config.services.tandoor-recipes.port}" = { };
      llama-swap.servers."localhost:${toString config.services.llama-swap.port}" = { };
      open-webui.servers."localhost:${toString config.services.open-webui.port}" = { };
      retrom.servers."localhost:${toString config.services.retrom.port}" = { };
    };

    virtualHosts = {
      "_" = {
        locations."/".return = "404";
      };

      "assistant.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://home-assistant";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "media.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://jellyfin";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "photos.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://immich";
        extraConfig = ''
          client_max_body_size 512m;
        '';
      };

      "kiosk.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://immich-kiosk";
      };

      "recipes.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://tandoor";
      };

      "llama.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://llama-swap";
          };
          "= /v1" = {
            proxyPass = "http://llama-swap";
            proxyWebsockets = true;
          };
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "llm.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://open-webui";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "games.home.arpa" = {
        addSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://retrom";
      };

      ${config.services.vaultwarden.domain} = {
        forceSSL = lib.mkForce false; # for acme http-01
        addSSL = true;
        enableACME = true;
      };

      ${config.services.searx.domain} = {
        addSSL = true;
        enableACME = true;
      };

      # "comfyui.opus.home.arpa" = {
      #   addSSL = true;
      #   sslCertificateKey = secrets."pki/nginx.key".path;
      #   sslCertificate = secrets."pki/nginx.crt".path;
      #   locations."/" = {
      #     proxyPass = "http://localhost:${toString config.impure.comfyui.port}";
      #   };
      # };

    };
  };
}
