{
  defaults = ./defaults;

  setup = ./setup;
  features = ./features;

  users = {
    containers = ./users/containers.nix;
    files = ./users/files.nix;
  };
}
