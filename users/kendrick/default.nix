{ pkgs, ... }:
{
  users.users.kendrick = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/kendrick";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      home-manager
    ];
  };
}
