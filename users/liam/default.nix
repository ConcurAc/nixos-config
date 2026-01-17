{
  pkgs,
  ...
}:
{
  users = {
    users.liam = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
      ];
      shell = pkgs.fish;
      packages = with pkgs; [
        home-manager
        brave
      ];
    };
  };

  security.pam.mount.extraVolumes = [
    "<path>/run/wrappers/bin:${pkgs.util-linux}/bin:${pkgs.gocryptfs}/bin:${pkgs.mergerfs}/bin</path>"
    ''
      <volume
        user="${cfg.name}"
        mountpoint="${cfg.home}/Games"
        path="mergerfs#${cfg.home}/.games:/srv/users/${cfg.name}/games=RO:/srv/games=RO"
        options="follow-symlinks=directory,category.create=ff"
        fstype="fuse"
        noroot="0"
      />
    ''
  ];
}
