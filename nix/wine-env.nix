{ pkgs }:

let
  wine = if pkgs.stdenv.isLinux then pkgs.wine64 else pkgs.wine;
in
{
  inherit wine;
  shellHook = ''
    # Setup isolated Wine environment for native Windows (WPF/WinForms) execution on NixOS
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
    export WINEPREFIX="''${WINEPREFIX:-$REPO_ROOT/.direnv/wine}"
    export WINEDEBUG="-all"
    export WINEARCH="win64"
    mkdir -p "$WINEPREFIX"

    echo -e "\033[0;32m[Windows / Wine] Isolated Wine prefix configured at .direnv/wine\033[0m"
    echo -e "\033[0;36m[Windows / Wine] Executing 'dotnet run' in Windows desktop projects automatically launches via Wine.\033[0m"
  '';
}
