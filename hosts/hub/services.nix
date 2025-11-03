{ config, pkgs, ... }:
let
  secrets = config.sops.secrets;
in
{
  imports = [
    ../../modules/services/invoke-ai.nix
  ];

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
    2049 # nfs
  ];

  services = {
    nfs.server = {
      enable = true;
      exports = ''
        /export 192.168.1.0/24(rw,crossmnt,fsid=0)
        /export/users 192.168.1.0/24(rw,insecure)
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
          locations."/" = {
            proxyPass = "http://localhost:8096";
          };
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
      };
    };

    # custom modules config
    invoke-ai = {
      enable = true;
      openFirewall = true;
      withGPU = true;
    };
  };
}
