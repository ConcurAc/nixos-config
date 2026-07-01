{
  config,
  lib,
  ...
}:
let
  cfg = config.users.containers;
in
{
  options.users.containers = with lib; {
    enable = mkEnableOption "Enables container based services.";
    interface = mkOption {
      type = types.str;
      description = "The physical network interface for the containers.";
    };
    withGpu = mkEnableOption "Pass gpu through to containers.";
    withInput = mkEnableOption "Pass uinput through to containers.";
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
            withGpu = mkOption {
              type = types.bool;
              description = "Pass gpu through to container";
              default = config.users.containers.withGpu;
              defaultText = lib.literalString "config.users.containers.withGpu";
            };
            overrides = mkOption {
              type = types.anything;
              default = { };
              description = "Overrides for container configuration.";
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
        base = {
          inherit (cfg) allowedDevices;

          autoStart = true;
          privateNetwork = true;

          macvlans = [ cfg.interface ];

          bindMounts = {
            ${cfgUser.hashedPasswordFile}.hostPath = lib.mkIf (
              !isNull cfgUser.hashedPasswordFile
            ) cfgUser.hashedPasswordFile;
            "/dev/dri" = lib.mkIf container.withGpu {
              hostPath = "/dev/dri";
              isReadOnly = false;
            };
          };

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
        };
      in
      lib.mkIf container.enable (lib.recursiveUpdate base container.overrides)
    ) cfg.users;
  };
}
