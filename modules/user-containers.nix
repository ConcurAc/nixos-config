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
      type = types.str;
      description = "The physical network interface for the containers.";
    };
    withGPU = mkEnableOption "Pass gpu through to container.";
    allowedDevices = mkOption {
      type = types.anything;
      default = [ ];
      description = "List of devices to allow access to container.";
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
            network = mkOption {
              type = types.enum [
                "none"
                "bridge"
                "macvlan"
              ];
              default = "none";
              description = "The physical network interface for the containers.";
            };
            bindMounts = mkOption {
              type = types.anything;
              default = { };
              description = "Extra bind mounts for container";
            };
            config = mkOption {
              type = types.anything;
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
        privateNetwork = true;

        macvlans = [ cfg.interface ];

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
          system = {
            inherit (config.system) stateVersion;
          };

          imports = [ container.config ];

          users = {
            users.${name} = cfgUser;
            mutableUsers = false;
          };

          networking.interfaces = {
            "mv-${cfg.interface}" = {
              useDHCP = lib.mkDefault true;
            };
          };
        };
      })
    ) cfg.users;
  };
}
