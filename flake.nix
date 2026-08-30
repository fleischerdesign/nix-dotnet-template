{
  description = "A reproducible .NET development environment with modern tooling, native Linux GUI (Avalonia/Uno), and native Windows (WPF/WinForms) support.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Granular builder helper for consumer flakes (Way A)
      mkDotnetShell =
        {
          pkgs,
          sdks ? [ "sdk_10_0" ],
          enableWindows ? false,
          enableNativeGui ? true,
          extraPackages ? [ ],
          env ? { },
          shellHook ? "",
        }:
        let
          builder = import ./nix/builder.nix { inherit pkgs; };
          baseShell = builder.mkDotnetShell {
            inherit
              sdks
              enableWindows
              enableNativeGui
              extraPackages
              ;
          };
        in
        baseShell.overrideAttrs (oldAttrs: {
          env = oldAttrs.env or { } // env;
          shellHook = (oldAttrs.shellHook or "") + "\n" + shellHook;
        });
    in
    {
      # Granular Library helper functions for consumer flakes
      lib = {
        inherit mkDotnetShell;
      };

      # Scaffolding templates for 'nix flake init' (Way B)
      templates = {
        default = {
          path = ./.;
          description = "A reproducible .NET cross-platform development environment (Console, Web APIs, Avalonia, MAUI)";
        };
        windows = {
          path = ./.;
          description = "A reproducible .NET native Windows (WPF/WinForms) development environment with NixOS Wine runner";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        defaultShell = mkDotnetShell {
          inherit pkgs;
          sdks = [ "sdk_10_0" ];
          enableWindows = false;
          enableNativeGui = true;
        };
        windowsShell = mkDotnetShell {
          inherit pkgs;
          sdks = [ "sdk_10_0" ];
          enableWindows = true;
          enableNativeGui = true;
        };
      in
      {
        # Pre-baked devShells
        devShells = {
          default = defaultShell;
          windows = windowsShell;
        };

        # Automated CI checks for 'nix flake check'
        checks = {
          default = defaultShell;
          windows = windowsShell;
        };

        # Executable apps for 'nix run'
        apps = {
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "dotnet-env-info" ''
              echo "=== .NET Nix Development Environment ==="
              ${pkgs.dotnet-sdk_10}/bin/dotnet --info
            '';
          };
        };

        # Standard Code Formatter
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
