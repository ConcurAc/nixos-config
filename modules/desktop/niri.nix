{ pkgs, ... }:
{
  programs = {
    niri = {
      enable = true;
    };

  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        gnome-keyring
      ];
    };
    terminal-exec.enable = true;
  };

  security.soteria.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    grim
    slurp
    wl-clipboard
    mako
  ];
}
