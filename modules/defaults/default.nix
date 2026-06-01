{
  resources,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = with inputs; [
    stylix.nixosModules.stylix

    ./bash.nix
    ./fish.nix
    ./yazi.nix

    ./gaming.nix
  ];

  time.timeZone = lib.mkDefault "Australia/Melbourne";

  i18n.defaultLocale = lib.mkDefault "en_AU.UTF-8";
  console = {
    font = lib.mkDefault "ter-v20b";
    packages = with pkgs; [ terminus_font ];
  };

  security.sudo-rs = {
    extraConfig = lib.mkDefault "Defaults pwfeedback";
  };

  stylix.base16Scheme = lib.mkDefault resources.palette.hephae-soft;
}
