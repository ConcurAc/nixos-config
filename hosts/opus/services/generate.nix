{ config, pkgs, ... }:
let
  secrets = config.sops.secrets;
  hosts = {
    localhost = "localhost:${toString config.services.comfyui.port}";
  };
in
{
  services.comfyui = {
    enable = true;
    enableManager = true;
    gpuSupport = "rocm";
    extraArgs = [
      "--lowvram"
      "--disable-xformers"
    ];
    environment = {
      HF_HOME = "/srv/ai/huggingface";
    };
    customNodes = {
          ComfyUI-Usgromana = pkgs.fetchFromGitHub {
            owner = "DayMan84";
            repo  = "ComfyUI-Usgromana";
            rev   = "2.0.4";
            hash  = "sha256-lg7OI9gc1reyqQvzgEzZgGDSD2g3yGOyWMRcpY868rQ=";
          };
        };
  };

  services.nginx.upstreams.comfyui.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."generate.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://comfyui";
    };
  };

  # services.kanidm.provision.systems.oauth2.comfyui = {
  #   displayName = "AI Generate";
  #   originUrl = "https://generate.home.arpa/oauth/oidc/callback";
  #   originLanding = "https://generate.home.arpa";
  #   basicSecretFile = secrets."kanidm/oauth2/comfyui".path;
  #   preferShortUsername = true;
  #   scopeMaps."users" = [
  #     "openid"
  #     "email"
  #     "profile"
  #     "groups"
  #   ];
  #   claimMaps.open-webui-roles.valuesByGroup = {
  #     "admins" = [ "comfyui-admin" ];
  #     "users" = [ "comfyui-user" ];
  #   };
  # };
}
