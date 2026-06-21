{
  config,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.opencloud.port}";
  };
in
{
  sops.secrets."opencloud.env" = {
    sopsFile = secrets/opencloud.env;
    format = "dotenv";
    key = "";
    owner = config.services.opencloud.user;
    group = config.services.opencloud.group;
  };

  services.opencloud = {
    enable = true;
    url = "https://cloud.home.arpa";

    settings = {
      proxy = {
        auto_provision_accounts = true;
        user_oidc_claim = "preferred_username";
        user_cs3_claim = "username";
        oidc = {
          rewrite_well_known = true;
        };
        role_assignment = {
          driver = "oidc";
          oidc_role_mapper = {
            role_claim = "opencloud-roles";
            role_mapping = [
              {
                role_name = "admin";
                claim_value = "opencloud-admin";
              }
              {
                role_name = "spaceadmin";
                claim_value = "opencloud-spaceadmin";
              }
              {
                role_name = "user";
                claim_value = "opencloud-user";
              }
              {
                role_name = "guest";
                claim_value = "opencloud-guest";
              }
            ];
          };
        };
        csp_config_file_override_location = pkgs.writeText "csp.yaml" (
          builtins.toJSON {
            directives = {
              connect-src = [
                "'self'"
                "blob: https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
                "https://update.opencloud.eu/"
                "https://id.home.arpa/"
              ];
            };
          }
        );
      };
    };
    environment = {
      OC_OIDC_ISSUER = "https://id.home.arpa/oauth2/openid/opencloud";
      OC_OIDC_CLIENT_ID = "opencloud";
      OC_EXCLUDE_RUN_SERVICES = "idp";
      PROXY_TLS = "false";
    };
    environmentFile = secrets."opencloud.env".path;
  };

  services.nginx = {
    upstreams.opencloud.servers.${hosts.localhost} = { };
    virtualHosts."cloud.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://opencloud";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.kanidm.provision.systems.oauth2.opencloud = {
    displayName = "Cloud";
    public = true;
    originUrl = [
      "https://cloud.home.arpa/oidc-callback.html"
      "oc://android.opencloud.eu"
    ];
    originLanding = "https://cloud.home.arpa";
    preferShortUsername = true;
    scopeMaps."users" = [
      "openid"
      "email"
      "profile"
      "offline_access"
    ];
    claimMaps.opencloud-roles.valuesByGroup = {
      "admins" = [ "opencloud-admin" ];
      "users" = [ "opencloud-user" ];
    };
    imageFile = builtins.fetchurl {
      name = "opencloud.png";
      url = "https://avatars.githubusercontent.com/u/188916550";
      sha256 = "sha256:0wzl7s7f6pzrwlamq0zdlndblkn1jz5x7x8inn9pr2678aq8wazx";
    };
  };
}
