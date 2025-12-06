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
    allowedDevices = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            node = mkOption {
              type = types.str;
              description = "Path to device node.";
              example = "/dev/net/tun";
            };
            modifier = mkOption {
              type = types.str;
              description = ''
                Device node access modifier. Takes a combination `r` (read), `w` (write), and `m` (mknod).
                See the `systemd.resource-control(5)` man page for more information.
              '';
              example = "rw";
            };
          };
        }
      );
      description = "List of devices to allow access to container.";
      default = [ ];
    };
    users = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkEnableOption "Enable this user's container.";
            withGPU = mkOption {
              type = types.bool;
              description = "Pass gpu through to container";
              default = config.user-containers.withGPU;
              defaultText = lib.literalString "config.user-containers.withGPU";
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
        }
      );
      description = "A mapping of user accounts to their container configuration.";
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    containers = lib.mapAttrs (
      name: container:
      let
        cfgUser = config.users.users.${name};
      in
      (lib.mkIf container.enable {
        inherit (cfg) allowedDevices;
        autoStart = true;
        macvlans = lib.mkIf container.withMacvlan [ cfg.interface ];

        bindMounts = {
          ${cfgUser.hashedPasswordFile}.hostPath = lib.mkIf (
            !isNull cfgUser.hashedPasswordFile
          ) cfgUser.hashedPasswordFile;
          "/dev/dri" = lib.mkIf container.withGPU {
            hostPath = "/dev/dri";
            isReadOnly = false;
          };
        }
        // container.bindMounts;

        config = {
          imports = [ container.config ];

          users = {
            users.${name} = cfgUser;
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
