{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.setup.fonts;
in
{
  options.setup.fonts = {
    enable = lib.mkEnableOption "...";
    emoji = lib.mkEnableOption "...";
    cjk = lib.mkEnableOption "...";
    lgc = lib.mkEnableOption "...";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages =
        with pkgs;
        [ noto-fonts ]
        ++ (lib.optional cfg.emoji noto-fonts-color-emoji)
        ++ (lib.optionals cfg.cjk [
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
        ])
        ++ (lib.optional cfg.lgc noto-fonts-lgc-plus);
    };
  };
}
