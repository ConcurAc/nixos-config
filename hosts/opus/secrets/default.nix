{
  sops.secrets."passwd" = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };
}
