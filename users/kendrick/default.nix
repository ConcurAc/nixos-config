{ pkgs, ... }:
{
  users.users.kendrick = {
    isNormalUser = true;
    home = "/home/kendrick";
    extraGroups = [
      "networkmanager"
    ];
    packages = with pkgs; [
      home-manager
    ];
  };
}
