{
  inputs,
  resources,
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

    # privateUsers = "pick";
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
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.hermes-agent.nixosModules.default
        inputs.retrom.nixosModules.retrom

        ./proxy.nix
        ./services.nix
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
        defaultSopsFile = ./secrets.yaml;
      };

      networking = {
        inherit hostName domain;
        interfaces.${macvlan} = {
          useDHCP = true;
        };
      };

      security = {
        apparmor.enable = true;
        pki.certificates = [
          (builtins.readFile resources.ca.cert.root)
        ];
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
