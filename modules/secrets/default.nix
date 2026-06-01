{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  filterDirs = path: lib.filterAttrs (_: value: value == "directory") (builtins.readDir path);
  recurseDir =
    path:
    lib.concatMap (
      name:
      let
        child = path + /${name};
        dirs = filterDirs child;
      in
      if dirs == { } then [ child ] else recurseDir child
    ) (lib.attrNames (filterDirs path));
in
{
  imports =
    with inputs;
    [
      sops-nix.nixosModules.sops
    ]
    ++ recurseDir ./.;

  environment.systemPackages = with pkgs; [
    sops
  ];
}
