{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./bash.nix
    ./fish.nix
    ./yazi.nix
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
}
