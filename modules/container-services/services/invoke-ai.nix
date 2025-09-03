{ config, lib, ... }:
let
  cfg = config.container-services;
  invokeAICfg = config.container-services.services.invoke-ai;
in
{
  options.container-services.services.invoke-ai = with lib; {
    enable = mkEnableOption "Enable the invoke-ai service.";
    withGPU = mkOption {
      type = types.bool;
      default = cfg.withGPU;
    };
    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    port = mkOption {
      type = types.int;
      default = 9090;
    };
    openFirewall = mkOption {
      type = types.bool;
    };
  };

  config = lib.mkIf config.container-services.enable {
    virtualisation.oci-containers.containers.invoke-ai = {
      image = "ghcr.io/invoke-ai/invokeai";
      hostname = "models.invoke.ai";
      ports = [
        "${invokeAICfg.host}:9090:${toString invokeAICfg.port}"
      ];
      volumes = [
        "invoke-ai:/invokeai"
      ];
      extraOptions = lib.mkIf invokeAICfg.withGPU [
        "--device=/dev/dri"
      ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf invokeAICfg.openFirewall [ invokeAICfg.port ];
  };
}
