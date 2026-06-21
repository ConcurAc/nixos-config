{ config, lib, ... }:
let
  inherit (config.sops) secrets;
in
{
  sops.secrets = {
    "vaultwarden.env" = {
      sopsFile = secrets/vaultwarden.env;
      format = "dotenv";
      key = "";
      owner = "vaultwarden";
      group = "vaultwarden";
    };
    "kanidm/oauth2/vaultwarden" = {
      sopsFile = ./secrets/oauth2.yaml;
      key = "oauth2/vaultwarden";
      owner = "kanidm";
      group = "kanidm";
    };
  };

  services.vaultwarden = {
    enable = true;
    configureNginx = true;
    domain = "passwords.home.arpa";
    config = {
      ENABLE_WEBSOCKET = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SSO_ENABLED = true;
      SSO_CLIENT_ID = "vaultwarden";
      SSO_AUTHORITY = "https://id.home.arpa/oauth2/openid/vaultwarden";
    };
    environmentFile = secrets."vaultwarden.env".path;
  };

  services.nginx.virtualHosts.${config.services.vaultwarden.domain} = {
    forceSSL = lib.mkForce false; # for acme http-01
    addSSL = true;
    enableACME = true;
  };

  services.kanidm.provision.systems.oauth2.vaultwarden = {
    displayName = "Passwords";
    public = true;
    originUrl = "https://passwords.home.arpa/identity/connect/oidc-signin";
    originLanding = "https://passwords.home.arpa";
    basicSecretFile = secrets."kanidm/oauth2/vaultwarden".path;
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
    ];
    imageFile = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/dani-garcia/vaultwarden/main/resources/vaultwarden-logo-auto.svg";
      sha256 = "sha256:15dmz8iivyq3824ip56kvznfrh2lg3mj5cvxnzyf17pa584sic76";
    };
  };
}
