{
  config,
  lib,
  ...
}:

{
  imports = [
    ./system.nix
    ./disks.nix
  ];

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      root-passwd.neededForUsers = true;
      deluge-auth = {
        owner = "deluge";
        group = "deluge";
      };
      proxy = {
        format = "binary";
        sopsFile = ./proxy.conf;
      };
    };
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.root-passwd.path;

  networking = {
    hostName = "cadence";
    networkmanager.enable = true;
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
  };

  services = {
    openvpn.servers.proxy.config = "config ${config.sops.secrets.proxy.path}";
    deluge = {
      enable = true;
      declarative = true;
      authFile = config.sops.secrets.deluge-auth.path;
      openFirewall = true;
      web = {
        enable = true;
        openFirewall = true;
      };
    };
  };

  systemd = {
    mounts = [
      {
        type = "nfs";
        what = "server:/archives";
        where = "/mnt/archives";
      }
      {
        type = "nfs";
        what = "server:/media";
        where = "/mnt/media";
      }
    ];
    automounts = [
      {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/archives";
      }
      {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/media";
      }
    ];
  };

}
