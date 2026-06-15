{
  assets,
  inputs,
  config,
  lib,
  ...
}:
let
  interface = "br-vlan100";
  macvlan = "mv-${interface}";

  hostName = "proxy";
  domain = "home.arpa";

  cfg = config.containers.${hostName}.config;
in
{
  containers.${hostName} = {
    autoStart = true;

    privateNetwork = true;

    macvlans = [ interface ];

    bindMounts = {
      ${cfg.sops.age.keyFile} = {
        hostPath = config.sops.age.keyFile;
      };
      "/dev/dri" = {
        hostPath = "/dev/dri";
        isReadOnly = false;
      };
      "/dev/kfd" = {
        hostPath = "/dev/kfd";
        isReadOnly = false;
      };
      "/var/lib" = {
        hostPath = "/var/lib";
        isReadOnly = false;
      };
      "/srv" = {
        hostPath = "/srv";
        isReadOnly = false;
      };
    };

    allowedDevices = [
      {
        node = "/dev/kfd";
        modifier = "rw";
      }
      {
        node = "/dev/dri/renderD128";
        modifier = "rw";
      }
    ];

    config = {
      imports = with inputs; [
        sops-nix.nixosModules.sops

        comfyui-nix.nixosModules.default
        retrom.nixosModules.retrom

        ./passwords.nix

        ./search.nix
        ./llama.nix
        ./llm.nix
        ./gen.nix

        ./media.nix

        ./photos.nix
        ./kiosk.nix

        ./recipes.nix
      ];

      nixpkgs.config = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "open-webui"
          ];
        rocmSupport = true;
      };

      sops = {
        age = {
          inherit (config.sops.age) keyFile;
        };
      };

      networking = {
        inherit hostName domain;
        interfaces.${macvlan} = {
          useDHCP = true;
        };
        firewall.allowedTCPPorts = [
          80 # http
          443 # https
        ];
      };

      security = {
        apparmor.enable = true;
        pki.certificates = [
          (builtins.readFile assets.ca.root)
        ];
        acme = {
          acceptTerms = true;
          defaults = {
            server = "https://ca.home.arpa/acme/acme/directory";
            email = "acme@scequ.com";
            validMinDays = 1;
            renewInterval = "hourly";
            group = "nginx";
          };
        };
      };

      services.nginx = {
        enable = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;

        virtualHosts = {
          "_" = {
            locations."/".return = "404";
          };
        };
      };

      time = {
        inherit (config.time) timeZone;
      };

      i18n = {
        inherit (config.i18n) defaultLocale;
      };

      system = {
        inherit (config.system) stateVersion;
      };
    };
  };
}
