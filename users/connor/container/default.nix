{
  assets,
  ...
}:
{
  imports = [
    ./media.nix
    ./notes.nix
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  security = {
    apparmor.enable = true;
    pki.certificates = [
      (builtins.readFile assets.ca.root)
    ];
    acme = {
      acceptTerms = true;
      defaults = {
        server = "https://ca.home.arpa/acme/acme/directory";
        email = "acme@scequ.com";
        validMinDays = 1;
        renewInterval = "hourly";
        group = "nginx";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    virtualHosts."_" = {
      locations."/".return = "404";
    };
  };
}
