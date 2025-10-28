{ pkgs, ... }:
{
  programs = {
    niri.enable = true;
    xwayland.enable = true;
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };
  };

  security.soteria.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard-rs
  ];
}
