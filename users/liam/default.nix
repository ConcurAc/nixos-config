{
  pkgs,
  ...
}:
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
