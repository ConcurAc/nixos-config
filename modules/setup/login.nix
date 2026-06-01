{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.setup.login;

  tuigreetCmd = lib.concatStringsSep " " (
    lib.filter (s: s != "") [
      (lib.getExe pkgs.tuigreet)
      (lib.optionalString cfg.time "--time")
      (lib.optionalString cfg.remember "--remember")
    ]
  );
in
{
  options.setup.login = {
    enable = lib.mkEnableOption "login customisation";
    time = lib.mkEnableOption "show clock in tuigreet";
    remember = lib.mkEnableOption "remember last selected session";
  };

  config = lib.mkIf cfg.enable {
    boot.plymouth.enable = lib.mkDefault true;

    services.greetd = {
      enable = true;
      useTextGreeter = true;
      greeterManagesPlymouth = true;
      settings = {
        default_session.command = tuigreetCmd;
      };
    };
  };
}
