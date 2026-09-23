{
  networking.firewall.allowedTCPPorts = [
    2049 # nfs
  ];

  services = {
    nfs.server = {
      enable = true;
      exports = ''
        /exports 192.168.0.0/16(rw,crossmnt,fsid=0)
        /exports/users 192.168.0.0/16(rw,insecure)
      '';
    };
  };

  fileSystems = {
    "/var/lib/immich" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=share/@immich"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/var/lib/comfyui" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=share/@comfyui"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/ai" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@ai"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/library" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "none";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@library"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/users" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@users"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/exports/users" = {
      device = "/srv/users";
      fsType = "none";
      options = [
        "bind"
        "nofail"
      ];
    };
    "/srv/media" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@media"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@archives"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/srv/share/games" = {
      device = "/dev/disk/by-label/Collection";
      fsType = "btrfs";
      options = [
        "x-systemd.mount-timeout=30s"
        "subvol=@games"
        "compress=zstd"
        "nofail"
        "noatime"
      ];
    };
    "/ext" = {
      device = "/dev/disk/by-label/Superior";
      fsType = "ext4";
      options = [
        "x-systemd.mount-timeout=30s"
        "nofail"
        "noatime"
      ];
    };
  };
}
