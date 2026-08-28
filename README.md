# .NET Flake Template

A reproducible, modern .NET 10 development environment with native WPF support on NixOS.

## Features

- **.NET 10 SDK & Tooling**: Pre-configured with `.NET 10`, `csharp-ls` (Roslyn LSP), `netcoredbg`, `csharpier`, and `nuget`.
- **NixOS WPF Support (`devShells.wpf`)**: Transparently builds WPF (`net10.0-windows`) on Linux via Roslyn and launches the GUI app automatically in an isolated Wine environment (`.direnv/wine`).
- **Transparent `dotnet` CLI**: No proprietary aliases to learn. Standard commands (`dotnet build`, `dotnet run`, `dotnet test`) work as expected out-of-the-box.
- **SOLID & DRY Design**: Clean separation of Flake declarations, modular environment building, transparent CLI wrapping, and Wine sandbox management.

## Usage

### 1. Cross-Platform .NET Development (Web APIs, Microservices, Console)

```bash
# Initialize a new standard .NET project
nix flake init -t github:fleischerdesign/nix-dotnet-template

# Enter the devshell (or use direnv)
nix develop

# Standard workflow
dotnet new console
dotnet run
```

### 2. WPF Windows Desktop Development on NixOS

```bash
# Initialize WPF environment
nix flake init -t github:fleischerdesign/nix-dotnet-template#wpf

# Enter WPF devshell
nix develop .#wpf

# Run your WPF application (compiles on NixOS, launches GUI via Wine)
dotnet run
```

## Structure

```
nix-dotnet-template/
├── flake.nix             # Flake entrypoint exposing default and WPF devShells
├── nix/
│   ├── builder.nix       # DRY devShell constructor
│   ├── dotnet-wrapper.nix# Transparent dotnet CLI wrapper script
│   └── wine-env.nix      # Isolated Wine prefix manager
├── .envrc                # direnv integration
└── .github/
    └── workflows/        # Reusable GitHub Actions workflow
```
