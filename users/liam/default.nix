{
  config,
  pkgs,
  ...
}:
let
  cfg = config.users.users.liam;
in
{
  users = {
    users.liam = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
      ];
      shell = pkgs.fish;
      packages = with pkgs; [
        home-manager
        brave
      ];
    };
  };
}
