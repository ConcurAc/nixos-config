{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    glib
  ];

  programs.yazi = {
    enable = true;
    initLua = ./init.lua;
    settings = {
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
            on = "u";
            run = "plugin restore";
            desc = "restore last trashed files/folders";
          }
          {
            on = [
              "M"
              "m"
            ];
            run = "plugin mount";
            desc = "mount drives";
          }
          {
            on = [
              "M"
              "c"
            ];
            run = "plugin gvfs -- select-then-mount";
            desc = "Select device then mount";
          }
          {
            on = [
              "M"
              "u"
            ];
            run = "plugin gvfs -- select-then-unmount";
            desc = "Select device then unmount";
          }
          {
            on = [
              "M"
              "a"
            ];
            run = "plugin gvfs -- add-mount";
            desc = "Add a GVFS mount URI";
          }
          {
            on = [
              "M"
              "e"
            ];
            run = "plugin gvfs -- edit-mount";
            desc = "Edit a GVFS mount URI";
          }
          {
            on = [
              "M"
              "r"
            ];
            run = "plugin gvfs -- remove-mount";
            desc = "Remove a GVFS mount URI";
          }
          {
            on = [
              "M"
              "g"
            ];
            run = "plugin gvfs -- jump-to-device";
            desc = "Select device then jump to its mount point";
          }
        ];
      };
    };
    plugins = {
      inherit (pkgs.yaziPlugins)
        restore
        mount
        rich-preview
        gvfs
        ;
    };
  };
}
