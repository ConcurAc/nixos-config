{
  config,
  pkgs,
  ...
}:
let
  interface = "br-vlan1100";
  macvlan = "mv-${interface}";

  hostName = "scequ";
  domain = "com";
  fqdn = "${hostName}.${domain}";

  cfg = config.containers.${hostName}.config;
in
{
  imports = [ ./mail.nix ];

  containers.${hostName} = {
    autoStart = true;

    privateUsers = "pick";
    privateNetwork = true;

    macvlans = [ interface ];

    config = {
      system = {
        inherit (config.system) stateVersion;
      };

      networking = {
        inherit hostName domain;
        interfaces.${macvlan} = {
          useDHCP = true;
        };
        firewall.allowedTCPPorts = [
          25
          80
          443
          465
          993
        ];
      };

      security = {
        acme = {
          acceptTerms = true;
          defaults = {
            email = "postmaster@scequ.com";
          };
        };
        apparmor.enable = true;
      };

      environment.systemPackages = [ pkgs.inetutils ];

      services = {
        nginx = {
          enable = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedGzipSettings = true;

          defaultSSLListenPort = 8443;
          defaultHTTPListenPort = 8080;

          upstreams = {
            immich-public-proxy.servers."localhost:${toString cfg.services.immich-public-proxy.port}" = { };
          };
          virtualHosts = {
            ${fqdn} = {
              addSSL = true;
              enableACME = true;
              locations."/".return = "404";
            };
            "photos.${fqdn}" = {
              addSSL = true;
              enableACME = true;
              locations."/".proxyPass = "http://immich-public-proxy";
            };
          };
        };
        haproxy = {
          enable = true;
          config = ''
            defaults
              timeout connect 5s
              timeout client  50s
              timeout server  50s

            frontend forward_http
              bind :80
              mode http

              default_backend nginx_http

            backend nginx_http
              mode http
              server nginx localhost:8080 check

            frontend forward_ssl
              bind :443
              mode tcp
              option tcplog
              tcp-request inspect-delay 5s
              tcp-request content accept if { req_ssl_hello_type 1 }

              use_backend mail.${fqdn}_ssl if { req.ssl_alpn acme-tls/1 }
              use_backend mail.${fqdn}_ssl if { req_ssl_sni -i mail.${fqdn} }
              use_backend mail.${fqdn}_ssl if { req_ssl_sni -i autoconfig.${fqdn} }
              use_backend mail.${fqdn}_ssl if { req_ssl_sni -i autodiscover.${fqdn} }

              default_backend nginx_ssl

            backend nginx_ssl
              mode tcp
              server nginx localhost:8443 check

            resolvers gateway
              nameserver dns 192.168.1.1:53

            backend mail.${fqdn}_ssl
              mode tcp
              server mail.${fqdn} mail.${fqdn}:443 check init-addr last,none resolvers gateway

            frontend forward_smtp
              bind :25
              mode tcp
              option tcplog
              tcp-request inspect-delay 5s
              default_backend mail.${fqdn}_smtp

            backend mail.${fqdn}_smtp
              mode tcp
              server mail.${fqdn} mail.${fqdn}:25 check init-addr last,none resolvers gateway

            frontend forward_submissions
              bind :465
              mode tcp
              option tcplog
              tcp-request inspect-delay 5s
              tcp-request content accept if { req_ssl_hello_type 1 }
              default_backend mail.${fqdn}_submissions

            backend mail.${fqdn}_submissions
              mode tcp
              server mail.${fqdn} mail.${fqdn}:465 check init-addr last,none resolvers gateway

            frontend forward_imaps
              bind :993
              mode tcp
              option tcplog
              tcp-request inspect-delay 5s
              tcp-request content accept if { req_ssl_hello_type 1 }
              default_backend mail.${fqdn}_imaps

            backend mail.${fqdn}_imaps
              mode tcp
              server mail.${fqdn} mail.${fqdn}:993 check init-addr last,none resolvers gateway
          '';
        };
        immich-public-proxy = {
          enable = true;
          immichUrl = "http://localhost:${toString config.services.immich.port}";
        };
      };
    };
  };
}
