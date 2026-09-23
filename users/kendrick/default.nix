{ pkgs, ... }:
{
  users.users.kendrick = {
    isNormalUser = true;
    home = "/home/kendrick";
    extraGroups = [
      "networkmanager"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      home-manager
    ];
  };
}
