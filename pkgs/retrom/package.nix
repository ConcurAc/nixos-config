{
  lib,
  fetchFromGitHub,
  pkg-config,
  rustPlatform,
  cargo-tauri,
  nodejs,
  pnpm_9,
  util-linux,
  openssl,
  perl,
  protobuf_29,
  webkitgtk_4_1,
  wrapGAppsHook3,
  glib-networking,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "retrom";
  version = "0.7.42";

  src = fetchFromGitHub {
    owner = "JMBeresford";
    repo = "retrom";
    rev = "v${finalAttrs.version}";
    hash = "sha256-j2yMF2v2bI5s0pejagrz0mtCaN3OlL9ALS9nlVaqUl4=";
  };

  cargoHash = "sha256-iZMqLZQNA0FabjYf++NCcE+7nQjP2N++WHMv7d+K/50=";
  buildAndTestSubdir = "packages/client";

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "sha256-tP+sRWBzA6t1Quf6/N0GtpWgxnqpJkVXDrQMY5uOnyw=";
  };

  nativeBuildInputs = [
    pkg-config
    nodejs
    pnpm_9.configHook
    perl
    protobuf_29
    util-linux
    cargo-tauri.hook
    wrapGAppsHook3
  ];

  buildInputs = [
    openssl
    webkitgtk_4_1
    glib-networking
  ];

  buildPhase = ''
    export CI=true
    export NX_NO_CLOUD=true
    export NX_DAEMON=false

    # See https://github.com/nrwl/nx/issues/22445
    cmd='pnpm nx build:desktop retrom-client-web'
    script -c "$cmd" /dev/null

    runHook tauriBuildHook
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "A centralized game library/collection management service with a focus on emulation";
    homepage = "https://github.com/JMBeresford/retrom";
    license = licenses.gpl3;
    platforms = platforms.all;
    mainProgram = finalAttrs.pname;
  };
})
