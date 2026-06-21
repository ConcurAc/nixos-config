{
  config,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = config.services.kanidm.server.settings.bindaddress;
  };
  kanidmSecret = {
    sopsFile = ./secrets/kanidm.yaml;
    owner = "kanidm";
    group = "kanidm";
  };
  oauth2Secret = {
    sopsFile = ./secrets/oauth2.yaml;
    owner = "kanidm";
    group = "kanidm";
  };
  acmeDir = config.security.acme.certs."id.home.arpa".directory;
in
{
  sops.secrets = {
    "kanidm/admin-password" = kanidmSecret;
    "kanidm/idm-admin-password" = kanidmSecret;
    "kanidm/oauth2/stalwart" = oauth2Secret // {
      key = "oauth2/stalwart";
    };
  };

  users.users.kanidm.extraGroups = [ "nginx" ];

  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_10;

    server = {
      enable = true;
      settings = {
        origin = "https://id.home.arpa";
        domain = "id.home.arpa";
        http_client_address_info.x-forward-for = [ "127.0.0.1" ];
        tls_chain = "${acmeDir}/fullchain.pem";
        tls_key = "${acmeDir}/key.pem";
      };
    };

    provision = {
      enable = true;
      autoRemove = false;
      adminPasswordFile = secrets."kanidm/admin-password".path;
      idmAdminPasswordFile = secrets."kanidm/idm-admin-password".path;
      groups."users" = { };
      groups."admins" = { };
    };
  };

  services.nginx = {
    upstreams.kanidm.servers.${hosts.localhost} = { };
    virtualHosts."id.home.arpa" = {
      addSSL = true;
      enableACME = true;
      locations."/".proxyPass = "https://kanidm";
    };
  };
}
