{
  pkgs,
  dotnetSdk,
  enableWindows ? false,
  wine ? pkgs.wine64,
}:

pkgs.writeShellScriptBin "dotnet" ''
  REAL_DOTNET="${dotnetSdk}/bin/dotnet"

  if [ "$1" = "run" ] && [ "${toString enableWindows}" = "1" ]; then
    # Check if current project targets Windows (WPF, WinForms, Win32)
    IS_WINDOWS_APP=0
    if find . -maxdepth 3 -name "*.csproj" -exec grep -qi "net.*-windows" {} + 2>/dev/null; then
      IS_WINDOWS_APP=1
    elif find . -maxdepth 3 -name "*.csproj" -exec grep -qi "UseWPF\|UseWindowsForms" {} + 2>/dev/null; then
      IS_WINDOWS_APP=1
    fi

    if [ "$IS_WINDOWS_APP" -eq 1 ]; then
      echo -e "\033[1;33m[NixOS Windows-Desktop] Building project via Linux .NET 10 SDK...\033[0m"
      $REAL_DOTNET build -p:EnableWindowsTargeting=true "''${@:2}" || exit $?

      # Find compiled executable
      EXE_PATH=$(find bin/ -type f -name "*.exe" 2>/dev/null | head -n 1)

      if [ -z "$EXE_PATH" ]; then
        echo -e "\033[1;31m[NixOS Windows Error] No compiled .exe binary found in bin/\033[0m"
        exit 1
      fi

      echo -e "\033[1;32m[NixOS Windows] Launching $EXE_PATH via Wine...\033[0m"
      export WINEPREFIX="''${WINEPREFIX:-$PWD/.direnv/wine}"
      export WINEDEBUG="-all"
      mkdir -p "$WINEPREFIX"
      exec ${wine}/bin/wine "$EXE_PATH"
    fi
  fi

  # Fallback to standard native Linux dotnet CLI for all other commands
  exec $REAL_DOTNET "$@"
''
