{ config, ... }:
let
  hosts = {
    localhost = "localhost:${toString config.services.open-webui.port}";
  };
in
{
  services.open-webui = {
    enable = true;
    port = 8060;
  };

  services.nginx.upstreams.open-webui.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."llm.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://open-webui";
      proxyWebsockets = true;
    };
    extraConfig = ''
      proxy_buffering off;
    '';
  };
}
