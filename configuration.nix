{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      retrom = super.callPackage ./pkgs/retrom/package.nix {};
      retrom-service = super.callPackage ./pkgs/retrom-service/package.nix {};
    })
  ];

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

  security.sudo-rs.enable = true;

  system.stateVersion = "25.05";
}
