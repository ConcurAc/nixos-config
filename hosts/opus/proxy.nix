{ config, lib, ... }:
let
  secrets = config.sops.secrets;
in
{
  sops.secrets = {
    "pki/nginx.key" = lib.mkIf config.services.nginx.enable {
      key = "pki/self.key";
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
    "pki/nginx.crt" = lib.mkIf config.services.nginx.enable {
      key = "pki/self.crt";
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "connorkouteris@gmail.com";
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
      ollama.servers."localhost:${toString config.services.ollama.port}" = { };
      retrom.servers."localhost:${toString config.services.retrom.port}" = { };
    };

    virtualHosts = {
      "home.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/" = {
          proxyPass = "http://home-assistant";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "passwords.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations = {
          "/".proxyPass = "http://vaultwarden";
          "= /notifications/anonymous-hub" = {
            proxyPass = "http://vaultwarden";
            proxyWebsockets = true;
          };
          "= /notifications/hub" = {
            proxyPass = "http://vaultwarden";
            proxyWebsockets = true;
          };
        };
      };

      "media.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/" = {
          proxyPass = "http://jellyfin";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "photos.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://immich";
        extraConfig = ''
          client_max_body_size 512m;
        '';
      };

      "kiosk.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://immich-kiosk";
      };

      "recipes.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://tandoor";
      };

      "llm.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://ollama";
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      "games.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://retrom";
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
