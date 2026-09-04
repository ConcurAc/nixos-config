{ pkgs, ... }:
{
  users.users.liam = {
    isNormalUser = true;
    uid = 1002;
    extraGroups = [
      "networkmanager"
      "gamemode"

      "games"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      home-manager
      brave
    ];
  };
}
