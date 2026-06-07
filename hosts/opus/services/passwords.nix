{ config, lib, ... }:
{
  services.vaultwarden = {
    enable = true;
    configureNginx = true;
    domain = "passwords.home.arpa";
    config = {
      ENABLE_WEBSOCKET = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };

  services.nginx.virtualHosts.${config.services.vaultwarden.domain} = {
    forceSSL = lib.mkForce false; # for acme http-01
    addSSL = true;
    enableACME = true;
  };
}
