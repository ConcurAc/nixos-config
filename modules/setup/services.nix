{ config, lib, ... }:
let
  cfg = config.setup.services;
in
{
  options.setup.services = {
    enable = lib.mkEnableOption "...";
    antivirus = lib.mkEnableOption "...";
  };

  config = lib.mkIf cfg.enable {
    services = {
      clamav = lib.mkIf cfg.antivirus {
        daemon.enable = lib.mkDefault true;
        scanner.enable = lib.mkDefault true;
        updater.enable = lib.mkDefault true;
      };
    };
  };
}
