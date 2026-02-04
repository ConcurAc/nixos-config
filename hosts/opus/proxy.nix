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

    upstreams = {
      stalwart.servers = builtins.listToAttrs (
        map (bind: {
          name = bind;
          value = { };
        }) config.services.stalwart-mail.settings.server.listener.http.bind
      );
      vaultwarden.servers."localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}" = { };
      jellyfin.servers."localhost:8096" = { };
      immich.servers."localhost:${toString config.services.immich.port}" = { };
    };

    virtualHosts = {
      "scequ.com" = {
        addSSL = true;
        enableACME = true;
        serverAliases = [
          "mail.scequ.com"
          "autoconfig.scequ.com"
          "autodiscover.scequ.com"
          "passwords.scequ.com"
        ];
      };

      "mail.scequ.com" = {
        forceSSL = true;
        useACMEHost = "scequ.com";
        locations."/".proxyPass = "http://stalwart";
      };

      "autoconfig.scequ.com" = {
        forceSSL = true;
        useACMEHost = "scequ.com";
        locations."/" = {
          proxyPass = "http://stalwart";
        };
      };

      "autodiscover.scequ.com" = {
        forceSSL = true;
        useACMEHost = "scequ.com";
        locations."/" = {
          proxyPass = "http://stalwart";
        };
      };

      "passwords.scequ.com" = {
        forceSSL = true;
        useACMEHost = "scequ.com";
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

      "mail.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://stalwart";
      };

      "media.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/" = {
          proxyPass = "http://jellyfin";
          proxyWebsockets = true;
        };
      };

      "photos.opus.home.arpa" = {
        addSSL = true;
        sslCertificateKey = secrets."pki/nginx.key".path;
        sslCertificate = secrets."pki/nginx.crt".path;
        locations."/".proxyPass = "http://immich";
      };
    };
  };
}
