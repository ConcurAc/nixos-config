{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.sops) secrets;
in
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
        owner = config.services.deluge.user;
        group = config.services.deluge.group;
      };
      proxy = {
        format = "binary";
        sopsFile = ./proxy.conf;
      };
    };
  };

  users.users.root.hashedPasswordFile = secrets.root-passwd.path;

  fileSystems = {
    "/srv/users" = {
      device = "hub:/users";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
    "/srv/archives" = {
      device = "hub:/archives";
      fsType = "nfs";
      options = [
        "x-systemd.mount-timeout=3s"
        "soft"
        "nofail"
        "noatime"
      ];
    };
  };

  networking = {
    hostName = "cadence";
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "192.168.1.5";
          prefixLength = 24;
        }
      ];
    };
    useDHCP = true;
    firewall.allowedTCPPorts = [
      80 # http
      443 # https
    ];
  };

  services = {
    openvpn.servers.proxy.config = "config ${secrets.proxy.path}";
    deluge = {
      enable = true;
      authFile = config.sops.secrets.deluge-auth.path;
      web.enable = true;
    };
    nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "deluge.local" = {
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.deluge.web.port}";
          };
        };
      };
    };
  };

  stylix = {
    enable = true;
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
  };
}
