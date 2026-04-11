{
  inputs,
  resources,
  config,
  ...
}:
let
  interface = "br-vlan100";
  macvlan = "mv-${interface}";

  hostName = "ca";
  domain = "home.arpa";

  cfg = config.containers.${hostName}.config;
in
{
  containers.${hostName} = {
    autoStart = true;

    privateUsers = "pick";
    privateNetwork = true;

    macvlans = [ interface ];

    bindMounts = {
      ${cfg.sops.age.keyFile} = {
        hostPath = config.sops.age.keyFile;
      };
    };

    config = {
      imports = [
        inputs.sops-nix.nixosModules.sops
        ./configuration.nix
      ];

      _module.args = {
        inherit resources;
      };

      sops = {
        age = {
          inherit (config.sops.age) keyFile;
        };
        defaultSopsFile = ./secrets.yaml;
      };

      networking = {
        inherit hostName domain;
        interfaces.${macvlan} = {
          useDHCP = true;
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
