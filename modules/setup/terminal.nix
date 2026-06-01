{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.setup.terminal;
in
{

  options.setup.terminal = {
    enable = lib.mkEnableOption "...";
    editor = lib.mkOption {
      type = lib.types.package;
      default = pkgs.helix;
    };
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    tui = lib.mkEnableOption "..." // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        EDITOR = cfg.editor.meta.mainProgram;
      };
      systemPackages =
        with pkgs;
        lib.optionals cfg.tui [
          bottom
        ]
        ++ [
          cfg.editor

          uutils-coreutils-noprefix

          eza
          zoxide
          bat
          ripgrep
          delta
          sd
          fd
          tokei
          hexyl
          dust
        ];
    };

    programs = {
      git.enable = lib.mkDefault true;

      yazi.enable = lib.mkDefault true;

      bash = {
        enable = lib.mkDefault true;
        shellAliases = cfg.aliases;
      };

      fish = {
        enable = lib.mkDefault true;
        shellAliases = cfg.aliases;
      };
    };

    documentation.man.enable = lib.mkDefault true;
  };
}
