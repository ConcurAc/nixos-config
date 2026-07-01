{ pkgs, ... }:
{
  users.users.liam = {
    isNormalUser = true;
    uid = 1002;
    extraGroups = [
      "networkmanager"

      "games"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      home-manager
      brave
    ];
  };
}
