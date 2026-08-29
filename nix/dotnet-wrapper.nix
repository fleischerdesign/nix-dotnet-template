{
  pkgs,
  dotnetSdk,
  enableWindows ? false,
  wine ? pkgs.wine64,
}:

pkgs.writeShellScriptBin "dotnet" ''
  REAL_DOTNET="${dotnetSdk}/bin/dotnet"

  if [ "$1" = "run" ] && [ "${toString enableWindows}" = "1" ]; then
    # Function to check if a csproj targets a runnable Windows Desktop app (WinExe, WPF/WinForms Exe)
    is_winexe() {
      local file="$1"
      [ -f "$file" ] || return 1

      # Exclude test projects and class libraries
      case "$file" in
        *.Tests.csproj|*.Test.csproj|*.UnitTests.csproj) return 1 ;;
      esac
      grep -iqE "<IsTestProject>\s*true\s*</IsTestProject>" "$file" && return 1
      grep -iqE "<OutputType>\s*Library\s*</OutputType>" "$file" && return 1

      # Must explicitly be a WinExe or an Exe with WPF/WinForms enabled
      if grep -iqE "<OutputType>\s*WinExe\s*</OutputType>" "$file"; then
        return 0
      fi

      if grep -iqE "<OutputType>\s*Exe\s*</OutputType>" "$file" && grep -iqE "<UseWPF>\s*true\s*</UseWPF>|<UseWindowsForms>\s*true\s*</UseWindowsForms>" "$file"; then
        return 0
      fi

      return 1
    }

    PROJECT_ARG=""
    APP_ARGS=()
    RUN_FLAGS=()
    IS_APP_ARG=0

    shift # Consume "run"

    while [ $# -gt 0 ]; do
      if [ "$IS_APP_ARG" -eq 1 ]; then
        APP_ARGS+=("$1")
        shift
        continue
      fi

      case "$1" in
        --)
          IS_APP_ARG=1
          shift
          ;;
        --project|-p)
          PROJECT_ARG="$2"
          RUN_FLAGS+=("$1" "$2")
          shift 2
          ;;
        --project=*)
          PROJECT_ARG="''${1#*=}"
          RUN_FLAGS+=("$1")
          shift
          ;;
        *)
          RUN_FLAGS+=("$1")
          shift
          ;;
      esac
    done

    APP_CS=""

    if [ -n "$PROJECT_ARG" ] && [ -f "$PROJECT_ARG" ]; then
      APP_CS="$PROJECT_ARG"
    elif [ -n "$PROJECT_ARG" ] && [ -d "$PROJECT_ARG" ]; then
      APP_CS=$(find "$PROJECT_ARG" -maxdepth 2 -name "*.csproj" | head -n 1)
    else
      # Check current directory first
      LOCAL_CS=$(find . -maxdepth 1 -name "*.csproj" | head -n 1)
      if [ -n "$LOCAL_CS" ] && is_winexe "$LOCAL_CS"; then
        APP_CS="$LOCAL_CS"
      else
        # Search repository root for any runnable WinExe project (excluding tests/ and bin/ directories)
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
        while IFS= read -r candidate; do
          if is_winexe "$candidate"; then
            APP_CS="$candidate"
            break
          fi
        done < <(grep -rlE "<OutputType>\s*WinExe\s*</OutputType>|<UseWPF>\s*true\s*</UseWPF>|<UseWindowsForms>\s*true\s*</UseWindowsForms>" --include="*.csproj" --exclude-dir={bin,obj,.direnv,.git,tests,Test,Tests} "$REPO_ROOT" 2>/dev/null)
      fi
    fi

    if [ -n "$APP_CS" ] && is_winexe "$APP_CS"; then
      echo -e "\033[1;33m[NixOS Windows-Desktop] Publishing $APP_CS (self-contained win-x64) via Linux .NET SDK...\033[0m"
      $REAL_DOTNET publish "$APP_CS" -r win-x64 --self-contained true -p:EnableWindowsTargeting=true "''${RUN_FLAGS[@]}" || exit $?

      APP_NAME=$(basename "$APP_CS" .csproj)
      ASM_NAME=$(sed -n 's:.*<AssemblyName>\([^<]*\)</AssemblyName>.*:\1:p' "$APP_CS" 2>/dev/null | head -n 1 | tr -d '\r ')
      if [ -n "$ASM_NAME" ]; then
        APP_NAME="$ASM_NAME"
      fi

      CS_DIR=$(dirname "$APP_CS")
      EXE_PATH=$(find "$CS_DIR/bin" -type f -path "*/publish/$APP_NAME.exe" 2>/dev/null | head -n 1)
      if [ -z "$EXE_PATH" ]; then
        EXE_PATH=$(find "$CS_DIR/bin" -type f -name "$APP_NAME.exe" 2>/dev/null | head -n 1)
      fi

      if [ -z "$EXE_PATH" ]; then
        echo -e "\033[1;31m[NixOS Windows Error] No compiled .exe binary found for $APP_CS\033[0m"
        exit 1
      fi

      REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
      export WINEPREFIX="''${WINEPREFIX:-$REPO_ROOT/.direnv/wine}"
      export WINEDEBUG="-all"
      export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
      export DXVK_STATE_CACHE_PATH="$WINEPREFIX"
      export DXVK_LOG_LEVEL="none"
      unset DOTNET_ROOT
      mkdir -p "$WINEPREFIX"

      echo -e "\033[1;32m[NixOS Windows] Launching $EXE_PATH via Wine (DXVK Vulkan graphics)...\033[0m"
      exec ${wine}/bin/wine "$EXE_PATH" "''${APP_ARGS[@]}"
    fi

    # Fall back to native dotnet run if not a WinExe project
    exec $REAL_DOTNET run "''${RUN_FLAGS[@]}" ''${IS_APP_ARG:+--} "''${APP_ARGS[@]}"
  fi

  # Native Linux CLI for everything else
  exec $REAL_DOTNET "$@"
''
