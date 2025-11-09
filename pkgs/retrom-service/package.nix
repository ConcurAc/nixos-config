{
  lib,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
  util-linux,
  pkg-config,
  rustPlatform,
  openssl,
  perl,
  protobuf_29,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "retrom-service";
  version = "0.7.42";

  src = fetchFromGitHub {
    owner = "JMBeresford";
    repo = "retrom";
    rev = "v${finalAttrs.version}";
    hash = "sha256-j2yMF2v2bI5s0pejagrz0mtCaN3OlL9ALS9nlVaqUl4=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "sha256-tP+sRWBzA6t1Quf6/N0GtpWgxnqpJkVXDrQMY5uOnyw=";
  };

  cargoHash = "sha256-iZMqLZQNA0FabjYf++NCcE+7nQjP2N++WHMv7d+K/50=";
  buildAndTestSubdir = "packages/service";

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
    util-linux
    pkg-config
    protobuf_29
    perl
  ];

  buildInputs = [
    openssl
  ];

  buildPhase = ''
    export CI=true
    export NX_NO_CLOUD=true
    export NX_DAEMON=false

    export VITE_BASE_URL=/web
    export VITE_UPTRACE_DSN=https://KgFBXOxX2RFeJurwr7R-4w@api.uptrace.dev?grpc=4317

     # See https://github.com/nrwl/nx/issues/22445
    cmd='pnpm nx build retrom-client-web'
    script -c "$cmd" /dev/null

    runHook cargoBuildHook
  '';

  postInstall = ''
    dst=$out/srv/www
    mkdir -p $dst

    # Work around for https://github.com/pnpm/pnpm/issues/5315
    cp -r packages/client-web/dist $dst

    cp pnpm-workspace.yaml $dst
    cp pnpm-lock.yaml $dst
    cp package.json $dst

    cp README.md $dst
    cp packages/client-web/vite.config.ts $dst

    cd $dst
    pnpm install --prod --offline --frozen-lockfile

    rm pnpm-workspace.yaml
    rm pnpm-lock.yaml
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
