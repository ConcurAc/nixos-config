{ pkgs, ... }:
{
  services = {
    desktopManager.gnome.enable = true;
    gnome = {
      core-apps.enable = false;
      gnome-remote-desktop.enable = true;
    };
    printing.enable = true;
  };
  environment.systemPackages = with pkgs; [
    baobab
    decibels
    loupe
    geary
    nautilus
    file-roller
    gnome-calendar
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-system-monitor
    gnome-connections

    ghostty
    wl-clipboard
  ];

  xdg.terminal-exec.enable = true;
}
