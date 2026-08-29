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
    {
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
        builder = import ./nix/builder.nix { inherit pkgs; };
      in
      {
        devShells = {
          default = builder.mkDotnetShell {
            sdks = [ "sdk_10_0" ];
            enableWindows = false;
            enableNativeGui = true;
          };

          windows = builder.mkDotnetShell {
            sdks = [ "sdk_10_0" ];
            enableWindows = true;
            enableNativeGui = true;
          };
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
