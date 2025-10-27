{ pkgs, ... }:
{
  programs = {
    niri.enable = true;
    xwayland.enable = true;
    uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "niri";
        comment = "niri compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri";
      };
    };
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
