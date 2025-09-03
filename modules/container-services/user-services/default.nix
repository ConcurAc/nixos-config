{
  config,
  lib,
  ...
}:

{
  imports = [
    ./container.nix
  ];
  options.container-services = with lib; {
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
}
