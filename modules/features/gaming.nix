{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.gaming;
in
{
  options.features.gaming = {
    enable = lib.mkEnableOption "Enable gaming features";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gamemode.enable = true;
      steam = {
        enable = config.nixpkgs.config.allowUnfree;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };
  };
}
