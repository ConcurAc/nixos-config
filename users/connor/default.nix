{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (config.sops) secrets;
  cfg = config.users.users.connor;
in
{
  imports =
    with inputs;
    [
      sops-nix.nixosModules.sops
    ]
    ++ [
      ../../modules/user-containers.nix
    ];

  sops.secrets = {
    "connor/passwd" = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
    "connor/age" = {
      sopsFile = ./secrets.yaml;
      path = "${cfg.home}/.config/sops/age/keys.txt";
      owner = cfg.name;
      group = cfg.group;
    };
  };

  users.users.connor = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/connor";
    hashedPasswordFile = secrets."connor/passwd".path;
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkxIAco0SzBIb8nGCL3QerUP7hp/kzv1gkHbmtoBVMp"
    ];
    shell = pkgs.fish;
    packages = [ pkgs.swtpm ];
  };

  user-containers.users.connor = {
    enable = true;
    bindMounts = {
      ${config.sops.age.keyFile}.hostPath = config.sops.age.keyFile;
      "/home/data".hostPath = "/srv/users/${cfg.name}";
    };
    config = {
      imports =
        with inputs;
        [
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
        ]
        ++ [
          ../../modules/terminal.nix
          ./container
        ];
      sops.age.keyFile = config.sops.age.keyFile;
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/brewer.yaml";
      };
    };
  };

  programs.fuse.userAllowOther = true;

  security.pam.mount.extraVolumes = [
    # CAN SOMEONE ACCEPT MY PR SO I CAN GET RID OF THIS
    # https://github.com/NixOS/nixpkgs/pull/453507
    "<path>/run/wrappers/bin:${pkgs.util-linux}/bin:${pkgs.gocryptfs}/bin:${pkgs.mergerfs}/bin</path>"
    ''
      <volume
        user="${cfg.name}"
        mountpoint="${cfg.home}/Games"
        path="mergerfs#${cfg.home}/.games:/srv/users/${cfg.name}/games=RO:/srv/games=RO"
        options="follow-symlinks=directory,category.create=ff"
        fstype="fuse"
        noroot="0"
      />
    ''
  ];
}
