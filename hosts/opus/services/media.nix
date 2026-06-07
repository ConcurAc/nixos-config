let
  hosts = {
    localhost = "localhost:8096";
  };
in
{
  services.jellyfin = {
    enable = true;
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
    };
  };
  networking.firewall = {
    allowedUDPPorts = [
      7359 # jellyfin autodiscover
    ];
  };

  services.nginx.upstreams.jellyfin.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."media.home.arpa" = {
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
}
