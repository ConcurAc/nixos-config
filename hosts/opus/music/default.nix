{
  assets,
  inputs,
  config,
  ...
}:
let
  interface = "br-vlan100";
  macvlan = "mv-${interface}";

  hostName = "music";
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
      "/var/lib" = {
        hostPath = "/var/lib";
        isReadOnly = false;
      };
    };

    config = {
      imports = with inputs; [
        sops-nix.nixosModules.sops

        ./music-assistant.nix
      ];

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
          80
          443
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
