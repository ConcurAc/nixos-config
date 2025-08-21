{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };

  services = {
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
