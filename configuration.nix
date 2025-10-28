# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:
{
  imports = [ ./modules/terminal.nix ];

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

  security.sudo-rs = {
    enable = true;
    extraConfig = "Defaults pwfeedback";
  };

  environment = {
    systemPackages = with pkgs; [
      uutils-coreutils-noprefix

      nil
      nixd

      wget
      curl
      openssh

      eza
      zoxide
      bat
      fd
      ripgrep
      fzf
      delta
      sd
      dust
      tlrc
      broot

      sops

      p7zip
      trash-cli
    ];
    variables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    git.enable = true;
    tmux.enable = true;
  };

  services = {
    openssh.enable = true;
  };

  documentation.man.enable = true;

  xdg = {
    terminal-exec.enable = true;
    portal.extraPortals = with pkgs; [
      xdg-desktop-portal-termfilechooser
    ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
