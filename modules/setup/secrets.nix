{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.setup.secrets;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.setup.secrets = {
    enable = lib.mkEnableOption "Enable secrets setup";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];
  };
}
