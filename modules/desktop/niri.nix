{ pkgs, ... }:
{
  programs = {
    niri = {
      enable = true;
      package = pkgs.niri;
    };
    xwayland.enable = true;
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };

  security.soteria.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard-rs
  ];
}
