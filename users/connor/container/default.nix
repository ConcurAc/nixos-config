{ config, lib, ... }:
let
  cfg = config.users.users.connor;
  secrets = config.sops.secrets;
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
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
      80 # http
      443 # https
    ];
  };

  console.enable = true;
  services = {
    openssh.enable = true;
    jellyfin = {
      enable = true;
      transcoding = {
        enableHardwareEncoding = true;
        hardwareDecodingCodecs = {
          av1 = true;
          h264 = true;
          vp9 = true;
        };
      };
    };
    polaris = {
      enable = true;
    };
    trilium-server = {
      enable = true;
    };
    livebook = {
      enableUserService = true;
      environment = {
        LIVEBOOK_PORT = 8058;
      };
      environmentFile = secrets."livebook.env".path;
    };

    nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;

      upstreams = {
        jellyfin.servers."localhost:8096" = { };
        polaris.servers."localhost:${toString config.services.polaris.port}" = { };
        trilium.servers."localhost:${toString config.services.trilium-server.port}" = { };
        livebook.servers."localhost:${toString config.services.livebook.environment.LIVEBOOK_PORT}" = { };
      };

      virtualHosts = {
        "connor.home.arpa" = {
          addSSL = true;
          sslCertificateKey = secrets."pki/nginx.key".path;
          sslCertificate = secrets."pki/nginx.crt".path;
          locations."/".return = "404";
        };
        "media.connor.home.arpa" = {
          addSSL = true;
          sslCertificateKey = secrets."pki/nginx.key".path;
          sslCertificate = secrets."pki/nginx.crt".path;
          locations."/" = {
            proxyPass = "http://jellyfin";
            proxyWebsockets = true;
          };
        };
        "music.connor.home.arpa" = {
          addSSL = true;
          sslCertificateKey = secrets."pki/nginx.key".path;
          sslCertificate = secrets."pki/nginx.crt".path;
          locations."/".proxyPass = "http://polaris";
        };
        "notes.connor.home.arpa" = {
          addSSL = true;
          sslCertificateKey = secrets."pki/nginx.key".path;
          sslCertificate = secrets."pki/nginx.crt".path;
          locations."/" = {
            proxyPass = "http://trilium";
            proxyWebsockets = true;
          };
        };
        "livebook.connor.home.arpa" = {
          addSSL = true;
          sslCertificateKey = secrets."pki/nginx.key".path;
          sslCertificate = secrets."pki/nginx.crt".path;
          locations."/".proxyPass = "http://livebook";
        };
      };
    };
  };
}
