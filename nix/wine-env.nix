{ pkgs }:

let
  wine = pkgs.wine64;
in
{
  inherit wine;
  shellHook = ''
    # Setup isolated Wine environment for native Windows (WPF/WinForms) execution on NixOS
    export WINEPREFIX="$PWD/.direnv/wine"
    export WINEDEBUG="-all"
    export WINEARCH="win64"
    mkdir -p "$WINEPREFIX"

    echo -e "\033[0;32m[Windows / Wine] Isolated Wine prefix configured at .direnv/wine\033[0m"
    echo -e "\033[0;36m[Windows / Wine] Executing 'dotnet run' in Windows desktop projects automatically launches via Wine.\033[0m"
  '';
}
