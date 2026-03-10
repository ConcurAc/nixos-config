{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;
    plugins = {
      lualine.enable = true;
      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          nil_ls.enable = true;
          statix.enable = true;
          lua_ls.enable = true;
        };
      };
      treesitter = {
        enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          json
          lua
          make
          markdown
          nix
          regex
          toml
          vim
          vimdoc
          xml
          yaml
        ];
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };
      telescope.enable = true;
      luasnip.enable = true;
      lint.enable = true;
      tiny-inline-diagnostic.enable = true;
      conform-nvim.enable = true;
      yazi.enable = true;
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
}
