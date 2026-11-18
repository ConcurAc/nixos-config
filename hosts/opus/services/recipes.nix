{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.tandoor-recipes.port}";
  };
in
{
  sops.secrets = {
    "tandoor.env" = lib.mkIf config.services.tandoor-recipes.enable {
      sopsFile = secrets/tandoor.env;
      key = "";
      format = "dotenv";
      owner = "tandoor_recipes";
      group = "tandoor_recipes";
    };
    "tandoor_oidc.json" = lib.mkIf config.services.tandoor-recipes.enable {
      sopsFile = secrets/tandoor_oidc.json;
      key = "";
      format = "json";
      owner = "tandoor_recipes";
      group = "tandoor_recipes";
    };
    "kanidm/oauth2/tandoor" = {
      sopsFile = ./secrets/oauth2.yaml;
      key = "oauth2/tandoor";
      owner = "kanidm";
      group = "kanidm";
    };
  };

  services.tandoor-recipes = {
    enable = true;
    port = 8082;
    database.createLocally = true;
    extraConfig = {
      MEDIA_ROOT = "/var/lib/tandoor-recipes/media";
      ALLOWED_HOSTS = "recipes.home.arpa";
      SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
      SOCIALACCOUNT_PROVIDERS_FILE = secrets."tandoor_oidc.json".path;
      SOCIALACCOUNT_EMAIL_AUTHENTICATION = "1";
      SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = "1";
    };
  };

  systemd.services.tandoor-recipes = {
    serviceConfig.EnvironmentFile = secrets."tandoor.env".path;
  };

  services.nginx = {
    upstreams.tandoor.servers.${hosts.localhost} = { };
    virtualHosts."recipes.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://tandoor";
    };
  };

  services.kanidm.provision.systems.oauth2.tandoor = {
    displayName = "Recipes";
    public = true;
    originUrl = "https://recipes.home.arpa/accounts/oidc/kanidm/login/callback/";
    originLanding = "https://recipes.home.arpa";
    basicSecretFile = secrets."kanidm/oauth2/tandoor".path;
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
    ];
    imageFile = "${pkgs.tandoor-recipes}/lib/tandoor-recipes/staticfiles/assets/brand_logo.svg";
  };
}
