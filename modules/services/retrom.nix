{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.retrom;
  home = "/var/lib/retrom-service";
  pgPort = config.services.postgresql.settings.port;
in
{
  options.services.retrom = {
    enable = lib.mkEnableOption "Enable retrom service";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.retrom-service;
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "retrom";
    };
    enableDatabase = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure the local postgresql database for retrom";
    };
    openFirewall = lib.mkEnableOption "Open firewall for TCP port";
    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          connection = lib.mkOption {
            type = lib.types.submodule {
              options = {
                dbUrl = lib.mkOption {
                  type = lib.types.str;
                  default = "postgres://${cfg.user}@localhost:${toString pgPort}/${cfg.user}";
                };
                port = lib.mkOption {
                  type = lib.types.int;
                  default = 5101;
                };
              };
            };
            default = { };
          };
          contentDirectories = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  path = lib.mkOption { type = lib.types.str; };
                  storageType = lib.mkOption {
                    type = lib.types.enum [
                      "MultiFileGame"
                      "SingleFileGame"
                    ];
                  };
                };
              }
            );
            example = [
              {
                path = "/app/library1/";
                storageType = "MultiFileGame";
              }
              {
                path = "/app/library2/";
                storageType = "SingleFileGame";
              }
            ];
          };
          igdb = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  clientId = lib.mkOption { type = lib.types.str; };
                  clientSecret = lib.mkOption { type = lib.types.str; };
                };
              }
            );
            default = null;
            example = {
              clientId = "1234";
              clientSecret = "my_super_secret_secret_in_plain_text";
            };
          };
          steam = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  apiKey = lib.mkOption { type = lib.types.str; };
                  userId = lib.mkOption { type = lib.types.str; };
                };
              }
            );
            default = null;
            example = {
              apiKey = "4321";
              userId = "1337";
            };
          };
        };
      };
      default = { };
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the configuration file. If this is set settings will be replaced by it";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${cfg.user} = {
        inherit home;
        createHome = true;
        isSystemUser = true;
        group = cfg.user;
      };
      groups.${cfg.user} = { };
    };

    services.postgresql = lib.mkIf cfg.enableDatabase {
      enable = true;
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ cfg.user ];
      authentication = ''
        local ${cfg.user} ${cfg.user} trust
        host ${cfg.user} ${cfg.user} 127.0.0.1/32 trust
        host ${cfg.user} ${cfg.user} ::1/128 trust
      '';
    };

    systemd.services.retrom = {
      description = "Retrom Service";
      after = [
        "network.target"
        "postgresql.target"
      ];

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = home;
        Environment = [
          "RETROM_DATA_DIR=${home}"
          "RETROM_WEB_DIR=${cfg.package}/srv/www"
          "RETROM_CONFIG=${
            if isNull cfg.configFile then
              pkgs.writeText "retrom-service-config.json" (builtins.toJSON cfg.settings)
            else
              cfg.configFile
          }"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.settings.connection.port ];
  };
}
