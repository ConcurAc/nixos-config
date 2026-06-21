{ config, pkgs, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.open-webui.port}";
  };
in
{
  sops.secrets = {
    "open-webui.env" = {
      sopsFile = secrets/open-webui.env;
      format = "dotenv";
      key = "";
    };
    "kanidm/oauth2/open-webui" = {
      sopsFile = ./secrets/oauth2.yaml;
      key = "oauth2/open-webui";
      owner = "kanidm";
      group = "kanidm";
    };
  };

  services.open-webui = {
    enable = true;
    port = 8060;
    environment = {
      WEBUI_URL = "https://llm.home.arpa";

      OPENID_PROVIDER_URL = "https://id.home.arpa/oauth2/openid/open-webui/.well-known/openid-configuration";
      OPENID_REDIRECT_URI = "https://llm.home.arpa/oauth/oidc/callback";

      OAUTH_PROVIDER_NAME = "Kanidm";
      OAUTH_CLIENT_ID = "open-webui";

      OAUTH_SCOPES = "openid email profile groups";

      OAUTH_ALLOWED_ROLES = "open-webui-user,open-webui-admin";
      OAUTH_ADMIN_ROLES = "open-webui-admin";
      OAUTH_ROLES_CLAIM = "open-webui-roles";

      OAUTH_CODE_CHALLENGE_METHOD = "S256";
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";

      ENABLE_OAUTH_SIGNUP = "true";
      ENABLE_OAUTH_ROLE_MANAGEMENT = "true";

      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
    environmentFile = secrets."open-webui.env".path;
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

  services.kanidm.provision.systems.oauth2.open-webui = {
    displayName = "AI Chat";
    originUrl = "https://llm.home.arpa/oauth/oidc/callback";
    originLanding = "https://llm.home.arpa";
    basicSecretFile = secrets."kanidm/oauth2/open-webui".path;
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
      "groups"
    ];
    claimMaps.open-webui-roles.valuesByGroup = {
      "admins" = [ "open-webui-admin" ];
      "users" = [ "open-webui-user" ];
    };
    imageFile = "${pkgs.open-webui}/lib/python3.13/site-packages/open_webui/static/favicon.svg";
  };
}
