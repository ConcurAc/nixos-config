{ pkgs, ... }:
{

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  time.timeZone = "Australia/Melbourne";

  i18n.defaultLocale = "en_AU.UTF-8";
  console = {
    font = "ter-v20b";
    packages = with pkgs; [ terminus_font ];
  };

  services = {
    openssh.enable = true;
  };

  security.sudo-rs.enable = true;

  system.stateVersion = "25.05";
}
