{
  config,
  lib,
  pkgs,
  ...
}:
let
  withUdisks = config.services.udisks2.enable;
in
{
  config = lib.mkIf config.programs.yazi.enable {
    environment.systemPackages = with pkgs; [
      trash-cli
    ];

    programs.yazi = {
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
          ]
          ++ lib.optional withUdisks {
            on = [
              "M"
            ];
            run = "plugin mount";
            desc = "mount drives";
          };
        };
      };
      plugins = {
        inherit (pkgs.yaziPlugins)
          restore
          rich-preview
          ;

        mount = lib.mkIf withUdisks pkgs.yaziPlugins.mount;
      };
    };
  };
}
