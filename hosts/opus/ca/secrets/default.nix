{ config, ... }:
{
  sops.secrets = {
    "step-ca/passwd" = {
      sopsFile = ./secrets.yaml;
      owner = config.systemd.services.step-ca.serviceConfig.User;
      group = config.systemd.services.step-ca.serviceConfig.Group;
    };
    "step-ca/secrets/intermediate_ca_key" = {
      sopsFile = ./secrets.yaml;
      owner = config.systemd.services.step-ca.serviceConfig.User;
      group = config.systemd.services.step-ca.serviceConfig.Group;
    };
  };
}
