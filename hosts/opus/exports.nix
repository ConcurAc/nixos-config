{
  networking.firewall.allowedTCPPorts = [
    2049 # nfs
  ];

  services = {
    nfs.server = {
      enable = true;
      exports = ''
        /exports 192.168.0.0/16(rw,crossmnt,fsid=0)
        /exports/library 192.168.0.0/16(rw,insecure)
        /exports/users 192.168.0.0/16(rw,insecure)
        /exports/media 192.168.0.0/16(rw,insecure)
        /exports/gallery 192.168.0.0/16(rw,insecure)
        /exports/archives 192.168.0.0/16(rw,insecure)
        /exports/games 192.168.0.0/16(rw,insecure)
      '';
    };
  };

  fileSystems = {
    "/var/lib/immich" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=share/@immich"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/ai" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@ai"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };

    "/srv/library" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@library"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/library" = {
      device = "/srv/library";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/users" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@users"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/users" = {
      device = "/srv/users";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/media" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@media"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/media" = {
      device = "/srv/media";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/gallery" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@gallery"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@archives"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/archives" = {
      device = "/srv/archives";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/crypto" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@crypto"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/games" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@games"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/games" = {
      device = "/srv/games";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/steam" = {
      device = "/dev/disk/by-label/Collection";
      options = [
        "x-systemd.mount-timeout=25s"
        "subvol=@steam"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/steam" = {
      device = "/srv/steam";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/bruce/media" = {
      device = "Bruce.home.arpa:/data/Media";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/bruce/music" = {
      device = "Bruce.home.arpa:/data/Music";
      fsType = "nfs";
      options = [
        "timeo=100"
        "retrans=3"
        "soft"
        "nofail"
        "noatime"
      ];
    };
  };
}
