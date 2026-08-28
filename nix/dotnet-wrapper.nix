{
  pkgs,
  dotnetSdk,
  enableWindows ? false,
  wine ? pkgs.wine64,
}:

pkgs.writeShellScriptBin "dotnet" ''
  REAL_DOTNET="${dotnetSdk}/bin/dotnet"

  if [ "$1" = "run" ] && [ "${toString enableWindows}" = "1" ]; then
    # Locate the runnable desktop app project: the WinExe project (test projects are libraries).
    # This is layout-agnostic and works whether the project sits at the repo root or under src/.
    APP_CS=$(grep -rl "WinExe" --include="*.csproj" --exclude-dir={bin,obj,.direnv} . 2>/dev/null | head -n 1)

    if [ -n "$APP_CS" ]; then
      echo -e "\033[1;33m[NixOS Windows-Desktop] Publishing $APP_CS (self-contained win-x64) via Linux .NET 10 SDK...\033[0m"
      $REAL_DOTNET publish "$APP_CS" -r win-x64 --self-contained true -p:EnableWindowsTargeting=true "''${@:2}" || exit $?

      # Resolve the assembly name: an explicit <AssemblyName> or the project file name. Matching
      # by name avoids picking helper executables (e.g. createdump.exe) from the publish output.
      APP_NAME=$(basename "$APP_CS" .csproj)
      ASM_NAME=$(sed -n 's:.*<AssemblyName>\([^<]*\)</AssemblyName>.*:\1:p' "$APP_CS" 2>/dev/null | head -n 1)
      if [ -n "$ASM_NAME" ]; then
        APP_NAME="$ASM_NAME"
      fi

      # Prefer the self-contained publish output (bundles the .NET runtime), then any app exe.
      # This avoids launching a framework-dependent Debug build that would need a runtime.
      EXE_PATH=$(find "$(dirname "$APP_CS")/bin" -type f -path "*/publish/$APP_NAME.exe" 2>/dev/null | head -n 1)
      if [ -z "$EXE_PATH" ]; then
        EXE_PATH=$(find "$(dirname "$APP_CS")/bin" -type f -name "$APP_NAME.exe" 2>/dev/null | head -n 1)
      fi

      if [ -z "$EXE_PATH" ]; then
        echo -e "\033[1;31m[NixOS Windows Error] No compiled .exe binary found for $APP_CS\033[0m"
        exit 1
      fi

      echo -e "\033[1;32m[NixOS Windows] Launching $EXE_PATH via Wine...\033[0m"
      export WINEPREFIX="''${WINEPREFIX:-$PWD/.direnv/wine}"
      export WINEDEBUG="-all"
      unset DOTNET_ROOT
      mkdir -p "$WINEPREFIX"
      exec ${wine}/bin/wine "$EXE_PATH"
    fi
    # No WinExe app project found -> fall through to the native dotnet run below.
  fi

  # Native Linux CLI for everything else, including non-Windows projects running in this shell.
  exec $REAL_DOTNET "$@"
''
