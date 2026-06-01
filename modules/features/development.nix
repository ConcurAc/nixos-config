{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development;
in
{
  options.features.development = {
    enable = lib.mkEnableOption "Enable development features";
    nix = lib.mkEnableOption "Enable development features";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      lib.optionals cfg.nix [
        nil
        nixd
      ];
  };
}
