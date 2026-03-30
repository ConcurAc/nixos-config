{
  inputs,
  config,
  lib,
  ...
}:
let
  interface = "br-vlan1100";
  macvlan = "mv-${interface}";

  hostName = "mail";
  domain = "scequ.com";
  fqdn = "${hostName}.${domain}";

  cfg = config.containers.${hostName}.config;

  secrets = cfg.sops.secrets;
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
      system = {
        inherit (config.system) stateVersion;
      };

      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = config.sops.age.keyFile;
        secrets = {
          "stalwart/admin_secret" = lib.mkIf cfg.services.stalwart.enable {
            owner = cfg.services.stalwart.user;
            group = cfg.services.stalwart.group;
          };
        };
      };

      networking = {
        inherit hostName domain;
        interfaces.${macvlan} = {
          useDHCP = true;
        };
      };

      security.apparmor.enable = true;

      services = {
        stalwart = {
          enable = true;
          openFirewall = true;
          settings = {
            server = {
              hostname = fqdn;
              listener = {
                smtp = {
                  bind = "[::]:25";
                  protocol = "smtp";
                };
                submissions = {
                  bind = "[::]:465";
                  protocol = "smtp";
                  tls.implicit = true;
                };
                imaps = {
                  bind = "[::]:993";
                  protocol = "imap";
                  tls.implicit = true;
                };
                https = {
                  bind = [ "[::]:443" ];
                  protocol = "http";
                  tls.implicit = true;
                };
              };
            };

            storage = {
              data = "rocksdb";
              fts = "rocksdb";
              blob = "rocksdb";
              lookup = "rocksdb";
              directory = "internal";
            };

            store = {
              rocksdb = {
                type = "rocksdb";
                path = "${cfg.services.stalwart.dataDir}/data";
                compression = "lz4";
              };
            };

            directory = {
              internal = {
                type = "internal";
                store = "rocksdb";
              };
            };

            authentication.fallback-admin = {
              user = "admin";
              secret = "%{file:${secrets."stalwart/admin_secret".path}}%";
            };
          };
        };
      };
    };
  };
}
