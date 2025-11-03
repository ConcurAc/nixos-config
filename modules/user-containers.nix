{
  config,
  lib,
  ...
}:
let
  cfg = config.user-containers;
in
{
  options.user-containers = with lib; {
    enable = mkEnableOption "Enables container based services.";
    interface = mkOption {
      type = types.nullOr types.str;
      description = "The physical network interface for the containers.";
    };
    withGPU = mkOption {
      type = types.bool;
      description = "Pass gpu through to container.";
      default = false;
    };
    users = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            container = {
              enable = mkEnableOption "Enable this user's container.";
              withGPU = mkOption {
                type = types.bool;
                description = "Pass gpu through to container";
                default = config.container-services.withGPU;
              };
              withMacvlan = mkOption {
                type = types.bool;
                description = "Create macvlans from network interfaces in container";
              };
              bindMounts = mkOption {
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      hostPath = mkOption {
                        type = types.str;
                      };
                      isReadOnly = mkOption {
                        type = types.bool;
                        default = true;
                      };
                    };
                  }
                );
                default = { };
                description = "Extra bind mounts for container";
              };
              config = mkOption {
                type = types.submodule {
                  freeformType = types.attrsOf types.anything;
                };
                default = { };
              };
            };
          };
        }
      );
      description = "A mapping of user accounts to their container configuration.";
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    containers = lib.mapAttrs (
      name:
      { container, ... }:
      let
        userCfg = config.users.users.${name};
      in
      (lib.mkIf container.enable {
        autoStart = true;
        macvlans = lib.mkIf container.withMacvlan [ cfg.interface ];

        allowedDevices = [
          (lib.mkIf container.withGPU {
            node = "/dev/dri";
            modifier = "rw";
          })
        ];

        bindMounts = {
          ${userCfg.hashedPasswordFile}.hostPath = lib.mkIf (
            userCfg.hashedPasswordFile != null
          ) userCfg.hashedPasswordFile;
          "/dev/dri" = lib.mkIf container.withGPU {
            hostPath = "/dev/dri";
            isReadOnly = false;
          };
        }
        // container.bindMounts;

        config = {
          imports = [ container.config ];

          users = {
            users.${name} = userCfg;
            mutableUsers = false;
          };

          networking.interfaces."mv-${cfg.interface}".useDHCP = lib.mkIf container.withMacvlan (
            lib.mkDefault true
          );

          system.stateVersion = config.system.stateVersion;
        };
      })
    ) cfg.users;
  };
}
