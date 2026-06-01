{
  config,
  lib,
  ...
}:
let
  cfg = config.setup.desktop;
in
{
  options.setup.desktop = {
    enable = lib.mkEnableOption "Enable desktop sessions";
    polkit = lib.mkEnableOption "Enable dedicated polkit";
    audio = lib.mkEnableOption "Enable audio" // {
      default = true;
    };
    mounts = lib.mkEnableOption "Enable mounts" // {
      default = true;
    };
    printing = lib.mkEnableOption "Enable printing";
  };

  config = lib.mkIf cfg.enable {
    security = {
      soteria.enable = lib.mkDefault cfg.polkit;
      rtkit.enable = lib.mkDefault cfg.audio;
    };

    services =
      lib.optionalAttrs cfg.audio {
        pipewire = {
          enable = true;
          pulse.enable = lib.mkDefault true;
          jack.enable = lib.mkDefault true;
          alsa.enable = lib.mkDefault true;
        };
      }
      // lib.optionalAttrs cfg.mounts {
        udisks2.enable = true;
        gvfs.enable = true;
      }
      // lib.optionalAttrs cfg.printing {
        printing.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      }
      // {
        upower.enable = lib.mkDefault true;
      };

  };
}
