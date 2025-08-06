{ pkgs, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Enable login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "tuigreet";
      };
    };
  };

  # Add greeter
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
  ];
}
