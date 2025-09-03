{ lib, ... }:
{
  imports = [
    ./services/invoke-ai.nix
    ./user-services
  ];

  options.container-services = with lib; {
    enable = mkEnableOption "Enables container based services.";
    interface = mkOption {
      type = types.nullOr types.str;
      description = "The physical network interface for the containers.";
    };
    withGPU = mkOption {
      type = types.bool;
      description = "Pass gpu through to container.";
      default = false;
    };
  };
}
