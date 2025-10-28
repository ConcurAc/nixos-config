{ pkgs, ... }:
let
  shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
  yaziSettings = {
    yazi = {
      mgr.ratio = [
        2
        4
        3
      ];
      plugin.prepend_previewers = [
        {
          name = "*.md";
          run = "rich-preview";
        }
        {
          name = "*.csv";
          run = "rich-preview";
        }
        {
          name = "*.json";
          run = "rich-preview";
        }
        {
          name = "*.rst";
          run = "rich-preview";
        }
        {
          name = "*.ipynb";
          run = "rich-preview";
        }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = "M";
          run = "plugin mount";
          desc = "mount drives";
        }
        {
          on = "u";
          run = "plugin restore";
          desc = "restore last trashed files/folders";
        }
      ];
    };
  };
in
{
  programs = {
    bash = {
      promptInit = ''
        y="$(tput setaf 11)"
        m="$(tput setaf 13)"
        c="$(tput setaf 14)"
        b="$(tput bold)"
        i="$(tput sitm)"
        r="$(tput sgr0)"

        PS1="(\[$b$y\]\u\[$r\]@\h \[$i$c\]\W\[$r\]) \[$b$m\]\@\[$r\] $ "

        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }
      '';
      inherit shellAliases;
    };

    fish = {
      enable = true;
      shellInit = ''
        function y
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
          end
          rm -f -- "$tmp"
        end
      '';
      interactiveShellInit = ''
        set fish_greeting ""
      '';
      inherit shellAliases;
    };

    nixvim = {
      enable = true;
      plugins = {
        lualine.enable = true;
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            nil_ls.enable = true;
            statix.enable = true;
          };
        };
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };
        telescope.enable = true;
        luasnip.enable = true;
        lint.enable = true;
        yazi = {
          enable = true;
          settings = yaziSettings;
        };
        cmp.enable = true;
        cmp-fuzzy-buffer.enable = true;
        cmp-fuzzy-path.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-treesitter.enable = true;
        cmp_luasnip.enable = true;

        nix.enable = true;
        nix-develop.enable = true;
        web-devicons.enable = true;
      };
    };
    yazi = {
      enable = true;
      settings = yaziSettings;
      plugins = with pkgs.yaziPlugins; {
        inherit restore mount rich-preview;
      };
    };
  };
}
