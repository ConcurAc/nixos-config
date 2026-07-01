{
  lib,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  python3,
  python3Packages,
  p7zip,
  unrar-free,
  tcl,
  tk,
}:
let
  pythonEnv = python3.withPackages (
    ps: with ps; [
      tkinter
      customtkinter
      darkdetect
      pillow
      pygobject3
      pycairo
      packaging
      requests
      keyring
      websocket-client
      msgpack
      importlib-metadata
      backports-tarfile
      lz4
      zstandard
      py7zr
      brotli
      inflate64
      multivolumefile
      psutil
      pybcj
      pycryptodomex
      pyppmd
      texttable
    ]
  );
  binPath = lib.makeBinPath [
    p7zip
    unrar-free
  ];
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "amethyst-mod-manager";
  version = "1.3.12";
  format = "other";
  src = fetchFromGitHub {
    owner = "ChrisDKN";
    repo = "Amethyst-Mod-Manager";
    rev = "v${finalAttrs.version}";
    hash = "sha256-BaUXj95kY+jG8CsXIeSXGFZ9K67sI9Oyjs6xg4eUy1U=";
  };
  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];
  buildInputs = [
    p7zip
    unrar-free
    tcl
    tk
  ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    share="$out/share/amethyst-mod-manager"
    mkdir -p "$share"
    cp -r src/* "$share"
    mkdir -p "$out/bin"
    for entry in gui:amethyst-mod-manager cli:amethyst-mod-manager-cli; do
      script="''${entry%%:*}.py"
      bin="''${entry##*:}"
      makeWrapper ${pythonEnv}/bin/python3 "$out/bin/$bin" \
        --chdir "$share" \
        --add-flags "$script" \
        --set MOD_MANAGER_GAMES "$share/Games" \
        --prefix XDG_DATA_DIRS : "$out/share" \
        --prefix PATH : "${binPath}" \
        --set TCL_LIBRARY "${tcl}/lib/tcl${tcl.version}" \
        --set TK_LIBRARY "${tk}/lib/tk${tk.version}"
    done
    for size in 64x64 128x128 256x256; do
      install -Dm644 src/appimage/mod-manager.png \
        "$out/share/icons/hicolor/$size/apps/io.github.Amethyst.ModManager.png"
    done
    runHook postInstall
  '';
  desktopItems = [
    (makeDesktopItem {
      name = "io.github.Amethyst.ModManager";
      desktopName = "Amethyst Mod Manager";
      comment = "Linux Mod Manager";
      exec = "amethyst-mod-manager";
      icon = "io.github.Amethyst.ModManager";
      terminal = false;
      categories = [
        "Game"
        "Utility"
      ];
      startupWMClass = "amethyst-mod-manager";
    })
  ];
  meta = {
    description = "A mod manager for Linux that uses Proton to run Windows modding tools";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "amethyst-mod-manager";
    maintainers = with lib.maintainers; [ ];
  };
})
