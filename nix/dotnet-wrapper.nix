{
  pkgs,
  dotnetSdk,
  enableWpf ? false,
  wine ? pkgs.wine64,
}:

pkgs.writeShellScriptBin "dotnet" ''
  REAL_DOTNET="${dotnetSdk}/bin/dotnet"

  if [ "$1" = "run" ] && [ "${toString enableWpf}" = "1" ]; then
    # Check if current directory or subdirectories contain WPF / Windows target projects
    IS_WPF=0
    if find . -maxdepth 3 -name "*.csproj" -exec grep -q "net.*-windows" {} + 2>/dev/null; then
      IS_WPF=1
    elif find . -maxdepth 3 -name "*.csproj" -exec grep -qi "UseWPF" {} + 2>/dev/null; then
      IS_WPF=1
    fi

    if [ "$IS_WPF" -eq 1 ]; then
      echo -e "\033[1;33m[NixOS WPF] Building project via Linux .NET 10 SDK...\033[0m"
      $REAL_DOTNET build "''${@:2}" || exit $?

      # Find compiled executable
      EXE_PATH=$(find bin/ -type f -name "*.exe" 2>/dev/null | head -n 1)

      if [ -z "$EXE_PATH" ]; then
        echo -e "\033[1;31m[NixOS WPF Error] No compiled .exe binary found in bin/\033[0m"
        exit 1
      fi

      echo -e "\033[1;32m[NixOS WPF] Launching $EXE_PATH via Wine...\033[0m"
      export WINEPREFIX="''${WINEPREFIX:-$PWD/.direnv/wine}"
      export WINEDEBUG="-all"
      mkdir -p "$WINEPREFIX"
      exec ${wine}/bin/wine "$EXE_PATH"
    fi
  fi

  # Fallback to standard native Linux dotnet CLI for all other commands
  exec $REAL_DOTNET "$@"
''
