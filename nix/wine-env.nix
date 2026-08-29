{ pkgs }:

let
  wine = if pkgs.stdenv.isLinux then pkgs.wine64 else pkgs.wine;
  dxvk = pkgs.dxvk;
  winetricks = pkgs.winetricks;
in
{
  inherit wine dxvk winetricks;
  shellHook = ''
    # Setup isolated Wine environment for native Windows (WPF/WinForms) execution on NixOS
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
    export WINEPREFIX="''${WINEPREFIX:-$REPO_ROOT/.direnv/wine}"
    export WINEDEBUG="-all"
    export WINEARCH="win64"
    export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
    mkdir -p "$WINEPREFIX"

    # Automated WPF rendering stack initialization (DXVK Vulkan, CoreFonts, D3DCompiler)
    WPF_INIT_FLAG="$WINEPREFIX/.wpf_initialized"
    if [ ! -f "$WPF_INIT_FLAG" ]; then
      echo -e "\033[1;33m[Windows / Wine] Optimizing WPF rendering pipeline (DXVK Vulkan, CoreFonts, d3dcompiler_47)...\033[0m"

      # Disable Wine Mono installer GUI prompt via Wine registry without breaking mscoree.dll
      ${wine}/bin/wine reg add "HKCU\Software\Wine\Mono" /v "Disabled" /t REG_SZ /d "1" /f >/dev/null 2>&1 || true

      # Install DXVK Vulkan DLL overrides into the Wine prefix (-f forces installation)
      ${dxvk}/bin/setup_dxvk.sh install -f --prefix "$WINEPREFIX" >/dev/null 2>&1 || true

      # Install Microsoft CoreFonts and D3DCompiler for HLSL shaders / drop shadows
      PATH="${wine}/bin:${winetricks}/bin:$PATH" ${winetricks}/bin/winetricks -q corefonts tahoma d3dcompiler_47 >/dev/null 2>&1 || true

      touch "$WPF_INIT_FLAG"
      echo -e "\033[0;32m[Windows / Wine] WPF rendering optimization complete.\033[0m"
    fi

    echo -e "\033[0;32m[Windows / Wine] Isolated Wine prefix configured at .direnv/wine\033[0m"
    echo -e "\033[0;36m[Windows / Wine] Executing 'dotnet run' in Windows desktop projects automatically launches via Wine.\033[0m"
  '';
}
