{ config, ... }:
let
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
  };

  services.nginx.upstreams.comfyui.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."gen.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://comfyui";
    };
  };
}
