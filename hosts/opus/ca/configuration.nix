{ resources, config, ... }:
let
  secrets = config.sops.secrets;
in
{
  sops.secrets = {
    "step-ca/passwd" = {
      owner = config.systemd.services.step-ca.serviceConfig.User;
      group = config.systemd.services.step-ca.serviceConfig.Group;
    };
    "step-ca/secrets/intermediate_ca_key" = {
      owner = config.systemd.services.step-ca.serviceConfig.User;
      group = config.systemd.services.step-ca.serviceConfig.Group;
    };
  };

  security = {
    apparmor.enable = true;
  };

  services = {
    step-ca = {
      enable = true;
      address = "0.0.0.0";
      port = 443;
      openFirewall = true;
      intermediatePasswordFile = secrets."step-ca/passwd".path;
      settings = {
        root = resources.ca.cert.root;
        crt = resources.ca.cert.intermediate;
        key = secrets."step-ca/secrets/intermediate_ca_key".path;
        address = ":443";
        dnsNames = [ "ca.home.arpa" ];
        db = {
          type = "badgerv2";
          dataSource = "/var/lib/step-ca/db";
        };
        authority = {
          provisioners = [
            {
              type = "ACME";
              name = "acme";
            }
          ];
        };
        tls = {
          cipherSuites = [
            "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
            "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
          ];
          minVersion = 1.2;
          maxVersion = 1.3;
          renegotiation = false;
        };
      };
    };
  };
}
