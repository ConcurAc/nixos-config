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
        server = "${lib.getExe' pkgs.llama-cpp-rocm "llama-server"} --port ${port} --no-ui";
        env = [
          "LLAMA_CACHE=/srv/ai/huggingface/hub"
        ];
      in
      {
        healthCheckTimeout = 60;
        models = {
          "qwen3.5-9b-uncensored" =
            let
              context = 128000;
            in
            {
              inherit env;
              cmd = "${server} -hf HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive:Q8_0 -c ${toString context}";
              checkEndpoint = "none"; # don't timeout download
              capabilities = {
                inherit context;
                "in" = [
                  "text"
                  "image"
                ];
                "out" = [ "text" ];
                "tools" = true;
              };
            };
          "gemma-4-e4b-uncensored" =
            let
              context = 128000;
            in
            {
              inherit env;
              cmd = "${server} -hf HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive:Q5_K_M -c ${toString context}";
              checkEndpoint = "none"; # don't timeout download
              capabilities = {
                inherit context;
                "in" = [
                  "text"
                  "image"
                  "audio"
                ];
                "out" = [ "text" ];
                "tools" = true;
              };
            };
          "qwopus3.5-9b-coder-mtp" =
            let
              context = 128000;
            in
            {
              inherit env;
              cmd = "${server} -hf Jackrong/Qwopus3.5-9B-Coder-MTP-GGUF:Q6_K -c ${toString context}";
              checkEndpoint = "none"; # don't timeout download
              capabilities = {
                inherit context;
                "in" = [
                  "text"
                  "image"
                ];
                "out" = [ "text" ];
                "tools" = true;
              };
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
