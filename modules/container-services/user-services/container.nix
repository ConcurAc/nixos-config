{
  config,
  lib,
  ...
}:

let
  cfg = config.container-services;
in
{
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
        };

        config = {
          imports = [ container.config ];

          users = {
            users.${name} = userCfg;
            mutableUsers = false;
          };

          services.avahi = lib.mkIf container.withMacvlan {
            enable = true;
            openFirewall = true;
          };

          networking.interfaces."mv-${cfg.interface}".useDHCP = lib.mkIf container.withMacvlan true;

          system.stateVersion = config.system.stateVersion;
        };
      })
    ) cfg.users;
  };
}
