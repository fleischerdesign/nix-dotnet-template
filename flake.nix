{
  description = "A reproducible .NET 10 development environment with modern tooling and native WPF support.";

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
          description = "A reproducible .NET 10 cross-platform development environment";
        };
        wpf = {
          path = ./.;
          description = "A reproducible .NET 10 WPF development environment with NixOS Wine runner";
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
            sdkVersion = "sdk_10_0";
            enableWpf = false;
          };

          wpf = builder.mkDotnetShell {
            sdkVersion = "sdk_10_0";
            enableWpf = true;
          };
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
