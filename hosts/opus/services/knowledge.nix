{ config, pkgs, ... }:
let
  inherit (config.sops) secrets;
  hosts = {
    localhost = "localhost:${toString config.services.outline.port}";
  };
in
{
  sops.secrets = {
    "oauth2/outline" = {
      sopsFile = secrets/oauth2.yaml;
      owner = config.services.outline.user;
      group = config.services.outline.group;
    };
    "kanidm/oauth2/outline" = {
      sopsFile = ./secrets/oauth2.yaml;
      key = "oauth2/outline";
      owner = "kanidm";
      group = "kanidm";
    };
  };

  services.outline = {
    enable = true;

    publicUrl = "https://knowledge.home.arpa";
    forceHttps = false;

    storage.storageType = "local";

    oidcAuthentication = {
      authUrl = "https://id.home.arpa/ui/oauth2";
      tokenUrl = "https://id.home.arpa/oauth2/token";
      userinfoUrl = "https://id.home.arpa/oauth2/openid/outline/userinfo";
      clientId = "outline";
      clientSecretFile = secrets."oauth2/outline".path;

      scopes = [
        "openid"
        "email"
        "profile"
      ];

      usernameClaim = "preferred_username";
      displayName = "Kanidm";
    };
  };

  services.nginx = {
    upstreams.outline.servers.${hosts.localhost} = { };
    virtualHosts."knowledge.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://outline";
        proxyWebsockets = true;
      };
    };
  };

  services.kanidm.provision.systems.oauth2.outline = {
    displayName = "Knowledge";
    allowInsecureClientDisablePkce = true;
    originUrl = "https://knowledge.home.arpa/auth/oidc.callback";
    originLanding = "https://knowledge.home.arpa";
    basicSecretFile = secrets."kanidm/oauth2/outline".path;
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
    ];
    imageFile = "${pkgs.outline}/share/outline/public/images/icon-512.png";
  };
}
