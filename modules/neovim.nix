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
