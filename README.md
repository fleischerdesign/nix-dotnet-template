# .NET Flake Template

A reproducible, modern, and truly agnostic .NET development environment for NixOS and Linux with native cross-platform GUI support (Avalonia, Uno Platform) and transparent Windows Desktop (WPF, WinForms) execution via Wine.

## Features

- **.NET SDK & Tooling**: Pre-configured with `.NET 10` (customizable/multi-targetable), `csharp-ls` (Roslyn LSP), `netcoredbg`, `csharpier`, and `nuget`.
- **Multi-SDK & Multi-Targeting Support**: Easily bundle multiple .NET SDK versions (e.g. .NET 8, 9, 10) in a single shell.
- **Native Cross-Platform GUI (`enableNativeGui`)**: Configures all required Linux X11, OpenGL, GTK, Fontconfig, ICU, and graphics libraries so frameworks like AvaloniaUI, Uno Platform, Raylib, and SkiaSharp run natively on NixOS out-of-the-box.
- **NixOS Native Windows Support (`devShells.windows` / `enableWindows`)**: Transparently builds Windows Desktop apps (`WPF`, `WinForms`, `net*-windows`) on Linux via Roslyn and launches the GUI app automatically in an isolated Wine sandbox (`.direnv/wine`).
- **Transparent & Robust `dotnet` CLI Wrapper**:
  - Supports `--project <path>` and `-p <path>` arguments.
  - Correctly separates publish build flags from application runtime arguments (`dotnet run -- arg1 arg2`).
  - Automatically falls back to native Linux execution for non-Windows projects.
- **SOLID & DRY Architecture**: Modular Nix design separating Flake entrypoint, devshell builder, CLI wrapper, and Wine environment manager.

## Usage

### 1. Cross-Platform .NET Development (Web APIs, Console, AvaloniaUI, Microservices)

```bash
# Initialize a new standard .NET project
nix flake init -t github:fleischerdesign/nix-dotnet-template

# Enter the devshell (or use direnv: 'use flake')
nix develop

# Standard workflow
dotnet new console
dotnet run
```

### 2. Native Windows Desktop Development (WPF, WinForms) on NixOS

```bash
# Initialize Windows Desktop environment
nix flake init -t github:fleischerdesign/nix-dotnet-template#windows

# Enter Windows devshell (or use direnv: 'use flake .#windows')
nix develop .#windows

# Run your Windows Desktop application (compiles on NixOS, launches GUI via Wine)
dotnet run
```

## Customizing Your DevShell

In your custom `flake.nix`, you can leverage `builder.mkDotnetShell` with flexible options:

```nix
devShells.default = builder.mkDotnetShell {
  # Accept string ("sdk_10_0"), package (pkgs.dotnetCorePackages.sdk_10_0), or list of multiple SDKs:
  sdks = [ "sdk_8_0" "sdk_10_0" ];

  # Enable native Linux GUI support (X11, GL, GTK, Fontconfig, ICU) for Avalonia/Uno
  enableNativeGui = true;

  # Enable transparent Windows Desktop runner via Wine
  enableWindows = false;

  # Additional CLI tools
  extraPackages = with pkgs; [ azure-cli docker ];

  # Additional environment variables
  extraEnv = {
    ASPNETCORE_ENVIRONMENT = "Development";
  };
};
```

## Structure

```
nix-dotnet-template/
├── flake.nix             # Flake entrypoint exposing default and windows devShells
├── nix/
│   ├── builder.nix       # Modular devShell builder (mkDotnetShell)
│   ├── dotnet-wrapper.nix# Robust, argument-aware dotnet CLI wrapper
│   └── wine-env.nix      # Isolated Wine prefix manager
├── .envrc                # direnv integration
└── .github/
    └── workflows/        # Reusable GitHub Actions workflow
```

## License

MIT / See [LICENSE](./LICENSE)
