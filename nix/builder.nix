{ pkgs }:

{
  mkDotnetShell =
    {
      sdkVersion ? "sdk_10_0",
      enableWindows ? false,
      extraPackages ? [ ],
    }:
    let
      dotnetSdk = pkgs.dotnetCorePackages.${sdkVersion};
      wineEnv = import ./wine-env.nix { inherit pkgs; };
      dotnetWrapper = import ./dotnet-wrapper.nix {
        inherit pkgs dotnetSdk enableWindows;
        wine = wineEnv.wine;
      };
    in
    pkgs.mkShell {
      packages = [
        dotnetWrapper
        pkgs.csharp-ls
        pkgs.netcoredbg
        pkgs.csharpier
        pkgs.nuget
      ] ++ (if enableWindows then [ wineEnv.wine ] else [ ]) ++ extraPackages;

      DOTNET_ROOT = "${dotnetSdk}";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "1";

      shellHook = ''
        echo -e "\033[1;34m=== .NET 10 Development Environment ===\033[0m"
        echo -e "SDK Version : \033[0;32m${dotnetSdk.version}\033[0m"
        echo -e "Tools       : \033[0;36mcsharp-ls, netcoredbg, csharpier, nuget\033[0m"
        ${if enableWindows then wineEnv.shellHook else ""}
      '';
    };
}
