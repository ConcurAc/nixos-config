{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };

  services.gnome.gnome-keyring.enable = true;

  security.soteria.enable = true;

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
    terminal-exec.enable = true;
  };

  environment.systemPackages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako
  ];
}
