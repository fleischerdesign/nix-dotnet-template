{ pkgs }:

{
  mkDotnetShell =
    {
      # SDK selection: string ("sdk_10_0"), package, or list of strings/packages
      sdks ? [ "sdk_10_0" ],
      sdkVersion ? null,

      # Enable Windows Desktop app support (WPF / WinForms via Roslyn + Wine)
      enableWindows ? false,

      # Enable native Linux GUI support (AvaloniaUI, Uno Platform, Raylib, SkiaSharp)
      enableNativeGui ? true,

      # Extra packages to add to the devshell
      extraPackages ? [ ],

      # Additional environment variables
      extraEnv ? { },

      # Custom shell hook script snippet
      extraShellHook ? "",
    }:
    let
      # Support legacy single sdkVersion or new sdks list
      rawSdks =
        if sdks != null && sdks != [ ] then
          (if builtins.isList sdks then sdks else [ sdks ])
        else if sdkVersion != null then
          [ sdkVersion ]
        else
          [ "sdk_10_0" ];

      resolveSdk =
        sdk:
        if builtins.isString sdk then
          pkgs.dotnetCorePackages.${sdk}
        else
          sdk;

      resolvedSdks = map resolveSdk rawSdks;
      dotnetSdk = pkgs.dotnetCorePackages.combinePackages resolvedSdks;

      isLinux = pkgs.stdenv.isLinux;
      enableWine = enableWindows && isLinux;

      wineEnv = import ./wine-env.nix { inherit pkgs; };

      dotnetWrapper = import ./dotnet-wrapper.nix {
        inherit pkgs dotnetSdk;
        enableWindows = enableWine;
        wine = wineEnv.wine;
      };

      # Common Linux GUI libraries for native desktop frameworks (Avalonia, Uno, SkiaSharp, etc.)
      guiLibs = with pkgs; [
        libx11
        libxcursor
        libxext
        libxi
        libxrandr
        libxrender
        libice
        libsm
        fontconfig
        freetype
        glib
        gtk3
        libglvnd
        icu
        zlib
        openssl
        libgdiplus
      ];

      guiLibraryPath = pkgs.lib.makeLibraryPath guiLibs;

      basePackages = [
        dotnetWrapper
        pkgs.csharp-ls
        pkgs.netcoredbg
        pkgs.csharpier
        pkgs.nuget
      ] ++ (if enableWine then [ wineEnv.wine ] else [ ]) ++ extraPackages;

      baseEnv = {
        DOTNET_ROOT = "${dotnetSdk}";
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        DOTNET_NOLOGO = "1";
        EnableWindowsTargeting = if enableWine then "true" else "false";
      } // (if enableNativeGui && isLinux then {
        LD_LIBRARY_PATH = guiLibraryPath;
      } else { }) // extraEnv;

    in
    pkgs.mkShell (
      baseEnv // {
        packages = basePackages;

        shellHook = ''
          echo -e "\033[1;34m=== .NET Development Environment ===\033[0m"
          echo -e "SDK Package : \033[0;32m${dotnetSdk.name}\033[0m"
          echo -e "Tools       : \033[0;36mcsharp-ls, netcoredbg, csharpier, nuget\033[0m"
          ${if enableNativeGui && isLinux then ''echo -e "Native GUI  : \033[0;32mEnabled (X11/GL/Fontconfig library paths configured)\033[0m"'' else ""}
          ${if enableWine then wineEnv.shellHook else if enableWindows then ''echo -e "\033[0;33m[Windows / Wine] Windows targeting enabled, but Wine is only supported on Linux.\033[0m"'' else ""}
          ${extraShellHook}
        '';
      }
    );
}
