{
  config,
  lib,
  pkgs,
  ...
}:
let
  hosts = {
    localhost = "localhost:${toString config.services.llama-swap.port}";
  };
in
{
  services.llama-swap = {
    enable = true;
    port = 11343;
    settings =
      let
        port = "\${PORT}";
        server = "${lib.getExe' pkgs.llama-cpp-rocm "llama-server"} --port ${port} --no-ui --offline";
        env = [
          "LLAMA_CACHE=/srv/ai/huggingface/hub"
        ];
      in
      {
        healthCheckTimeout = 60;
        models = {
          "qwen3.5-9b-uncensored" = {
            inherit env;
            cmd = "${server} -hf HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive:Q8_0 -c 128000";
            checkEndpoint = "none"; # don't timeout download
          };
          "gemma-4-e4b-uncensored" = {
            inherit env;
            cmd = "${server} -hf HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive:Q5_K_M -c 128000";
            checkEndpoint = "none"; # don't timeout download
          };
        };
      };
  };
  systemd.services.llama-swap.serviceConfig.BindPaths = [
    "/srv/ai/huggingface"
  ];

  services.nginx.upstreams.llama-swap.servers.${hosts.localhost} = { };
  services.nginx.virtualHosts."llama.home.arpa" = {
    addSSL = true;
    enableACME = true;
    locations = {
      "/" = {
        proxyPass = "http://llama-swap";
      };
      "= /v1" = {
        proxyPass = "http://llama-swap";
        proxyWebsockets = true;
      };
    };
    extraConfig = ''
      proxy_buffering off;
      client_max_body_size 50M;
    '';
  };
}
