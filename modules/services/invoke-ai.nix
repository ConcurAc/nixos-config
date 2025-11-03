{ config, lib, ... }:
let
  cfg = config.services.invoke-ai;
in
{
  options.services.invoke-ai = with lib; {
    enable = mkEnableOption "Enable the invoke-ai service.";
    withGPU = mkOption {
      type = types.bool;
      default = true;
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

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.invoke-ai = {
      image = "ghcr.io/invoke-ai/invokeai";
      hostname = "models.invoke.ai";
      ports = [
        "${cfg.host}:${toString cfg.port}:9090"
      ];
      volumes = [
        "invoke-ai:/invokeai"
      ];
      extraOptions = lib.mkIf cfg.withGPU [
        "--device=/dev/dri"
      ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
