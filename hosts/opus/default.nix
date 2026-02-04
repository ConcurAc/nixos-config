{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
in
{
  imports = [
    ./system.nix
    ./disks.nix
    ./services.nix
    ./proxy.nix
    ../../modules/user-containers.nix
    ../../modules/impure/comfyui.nix
  ];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      allowUnfree = true;
      rocmSupport = true;
    };
  };

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      root-passwd = {
        neededForUsers = true;
      };
    };
  };

  users.users.root.hashedPasswordFile = secrets.root-passwd.path;

  boot.plymouth.enable = true;

  hardware = {
    steam-hardware.enable = true;
  };

  security = {
    pki.certificates = [
      ''
        self-signed
        ===========
        -----BEGIN CERTIFICATE-----
        MIIFcTCCA1mgAwIBAgIUT3kSGROdPJps+aICyB9ADf1c1qgwDQYJKoZIhvcNAQEL
        BQAwSDELMAkGA1UEBhMCQVUxETAPBgNVBAgMCFZpY3RvcmlhMRIwEAYDVQQHDAlN
        ZWxib3VybmUxEjAQBgNVBAMMCWhvbWUuYXJwYTAeFw0yNjAxMjMwNjQ4NTRaFw0z
        NjAxMjEwNjQ4NTRaMEgxCzAJBgNVBAYTAkFVMREwDwYDVQQIDAhWaWN0b3JpYTES
        MBAGA1UEBwwJTWVsYm91cm5lMRIwEAYDVQQDDAlob21lLmFycGEwggIiMA0GCSqG
        SIb3DQEBAQUAA4ICDwAwggIKAoICAQDibC3vzJFZreDagKGnIf34pTU7hymjWnGI
        /RD24G8DNJCdy146SL9cb7l/OquSdtYDgoGlmxAEdv/wLcDXE0+OpegkXn65W5ft
        eQQ41faH94ikeqlvoc/jqtGfbNC5apwzvUOsKVn85NrqW/rKqIOoBjmDuRtzjroT
        lpqTQdkmae+WGPLCgvRJyD/qykQv2Bik1K+RRdYIotp46I3bl1tx3iT8oIFXdKCv
        VDeyQk2SudMuofXY7avLnPCqFBYnxLAf8TTom7Ld/b25DeJVfTjc1qtk+TTIrX4C
        QLF9i9Ec7GpStHCgy3kmXLkXozaxTFTMkOlNJjtywbWT+guC+eEXXIpO6GpKIsaT
        nYLuybWLnRRHCOD0tT+XabUGE/ZTrwd/Fu2+A8TVAAVjh0gUqmSYoLmK3e+J7U8y
        RE5Gcf7Agqf8zKaL0LN1yTeKzNQ1VkCmgEI/svuxgffFgnN1LGCUriNblM3/Ayqa
        qm7VOiIYyR4obyHdbDkNH/XRP8OqeNsgXnlf1afMoGgJuiSsXcNfTNHNVlIo9Xin
        gqUnClqkkO7Xa7zhItajUkUAb0yseyeaZ3xst1VgPJLNzok+FHqPcKqejf1Kxtbx
        F2uD/TIv1Ukv+djXVPmFEYb5EJK7T2X8dRVRda60/NMzgWplpR9ZJX9RYydYJDzx
        ssKYOIBqtQIDAQABo1MwUTAdBgNVHQ4EFgQU7Jey6MTX/OeHgS8WiAcShoiNKzQw
        HwYDVR0jBBgwFoAU7Jey6MTX/OeHgS8WiAcShoiNKzQwDwYDVR0TAQH/BAUwAwEB
        /zANBgkqhkiG9w0BAQsFAAOCAgEAUA3/DJO+ZsCcGbro/TgfUbZrZHQoQ62AGiDD
        cXIF8vIriKJsasHP9VQQzQhQlurU+Tcv5Dz5HZt/6iSPgET31lN8+YMvFonkb8E0
        T3UInG/86CSadLbIQL/9dZeBjYy0uuYLuUDY44ZBl1EFOm+SwvWLgNjeRNULxuF8
        lBywOB6kEuI9kSyyL79Q7xgLzeBnniDV0KPHX57QclNTANmgfrBwwDZ8MFnGglXx
        h643S/s23bMvTok6LZNAdN0Mlw6rILKeCQqQxyCGz8r578gdhwE23Uu+HNh9RAhA
        g034brx3QXIY3sDn59wax9qSd5zhzCbDWFVuvhJrwi5ZofnGiQMjoeJcADGKqCr8
        8L8dhOq5fRBNKQzOBEQVTdnQ1OO56n9/yB+zbdeuE6iwxky3lvp/NUtFFz11UjZ/
        DOmFBbAXN7Te772vRAfw5rOojutTV0HQ7X2hHM06zHxvdOzxYbuNRjb9hyU2e6Rh
        1zRUNT1SthwlhPROcjMEXY4AC6CL5WFeC35iufve5+vqYFC36AuEJ0U1Gs1N71v5
        6tgteOBp73BsKaPRelCYQdSXAiNS42y3U45JL3ecWdZEugV55hb/d2JqUt9zCu0V
        IoXr7t4e7Afhq1Dy4CY0YGSmT1VDxBmlSAPm3TQyIP0Dcc/lgkkjzt8e21n/1ME2
        PK+w4Po=
        -----END CERTIFICATE-----
      ''
    ];
    pam.mount = {
      enable = true;
      createMountPoints = true;
      fuseMountOptions = [
        "nodev"
        "nosuid"
      ];
      additionalSearchPaths = with pkgs; [
        gocryptfs
        mergerfs
      ];
    };
  };

  networking = {
    hostName = "opus";
    domain = "home.arpa";
    useDHCP = lib.mkDefault true;
    vlans = {
      vlan100 = {
        id = 100;
        interface = "enp7s0";
      };
    };
    interfaces = {
      enp7s0 = {
        wakeOnLan.enable = true;
      };
      vlan100 = {
        useDHCP = true;
      };
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in
    [
      "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    ];

  environment.systemPackages = with pkgs; [
    waypipe
    xwayland-run
  ];

  programs = {
    nix-ld.enable = true;
    steam.enable = true;
    gamemode.enable = true;
  };

  services = {
    desktopManager = {
      cosmic = {
        enable = true;
        xwayland.enable = true;
      };
    };
    displayManager.cosmic-greeter.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  stylix = {
    enable = true;
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/hopscotch.yaml";
  };
}
