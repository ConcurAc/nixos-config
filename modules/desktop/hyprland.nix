{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    hyprlock.enable = true;
  };

  services = {
    hypridle.enable = true;

    pipewire.enable = true;

    # Enable login manager
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "tuigreet";
        };
      };
    };
  };

  # Add greeter
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
  ];
}
