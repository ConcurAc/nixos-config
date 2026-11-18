{ config, pkgs, ... }:
let
  inherit (config.sops) secrets;
  hosts = {
    localhost = "localhost:${toString config.services.kavita.settings.Port}";
  };
in
{
  sops.secrets = {
    "kavita/token_key" = {
      sopsFile = secrets/kavita.yaml;
      key = "token_key";
      owner = config.services.kavita.user;
    };
    "oauth2/kavita" = {
      sopsFile = secrets/oauth2.yaml;
      owner = config.services.kavita.user;
    };
    "kanidm/oauth2/kavita" = {
      sopsFile = ./secrets/oauth2.yaml;
      key = "oauth2/kavita";
      owner = "kanidm";
      group = "kanidm";
    };
  };

  services.kavita = {
    enable = true;
    settings = {
      IpAddresses = "::1,127.0.0.1";
      OpenIdConnectSettings = {
        Enabled = true;
        Authority = "https://id.home.arpa/oauth2/openid/kavita";
        ClientId = "kavita";
        Secret = "@oidc_client_secret@";
        CustomScopes = [
          "email"
          "profile"
        ];
      };
      Port = 5001;
      TokenKey = "@token_key@";
    };
    credentials = {
      oidc_client_secret = secrets."oauth2/kavita".path;
      token_key = secrets."kavita/token_key".path;
    };
  };

  services.nginx = {
    upstreams.kavita.servers.${hosts.localhost} = { };
    virtualHosts."library.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://kavita";
    };
  };

  services.kanidm.provision.systems.oauth2.kavita = {
    displayName = "Library";
    originUrl = [
      "https://library.home.arpa/signin-oidc"
      "https://library.home.arpa/signout-callback-oidc"
    ];
    originLanding = "https://library.home.arpa";
    basicSecretFile = secrets."kanidm/oauth2/kavita".path;
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
    ];
    imageFile = "${pkgs.kavita}/lib/kavita/frontend/browser/assets/images/logo.png";
  };
}
