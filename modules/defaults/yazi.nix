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
              mime = "text/markdown";
              run = "rich-preview";
            }
            {
              mime = "text/csv";
              run = "rich-preview";
            }
            {
              mime = "application/json";
              run = "rich-preview";
            }
            {
              mime = "text/x-rst";
              run = "rich-preview";
            }
            {
              mime = "application/x-ipynb+json";
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
