let
  hosts = {
    localhost = "localhost:8096";
  };
in
{
  services.jellyfin = {
    enable = true;
    user = "connor";
    group = "connor";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
    };
  };
  networking.firewall.allowedUDPPorts = [
    7359 # jellyfin autodiscover
  ];

  services.nginx = {
    upstreams.jellyfin.servers.${hosts.localhost} = { };
    virtualHosts."media.connor.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://jellyfin";
        proxyWebsockets = true;
      };
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
}
