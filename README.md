# .NET Flake Template

A reproducible, modern .NET 10 development environment with native Windows (WPF, WinForms) support on NixOS.

## Features

- **.NET 10 SDK & Tooling**: Pre-configured with `.NET 10`, `csharp-ls` (Roslyn LSP), `netcoredbg`, `csharpier`, and `nuget`.
- **NixOS Native Windows Support (`devShells.windows`)**: Transparently builds Windows apps (`net10.0-windows`, WPF, WinForms) on Linux via Roslyn and launches the GUI app automatically in an isolated Wine environment (`.direnv/wine`).
- **Transparent `dotnet` CLI**: No proprietary aliases to learn. Standard commands (`dotnet build`, `dotnet run`, `dotnet test`) work as expected out-of-the-box.
- **SOLID & DRY Design**: Clean separation of Flake declarations, modular environment building, transparent CLI wrapping, and Wine sandbox management.

## Usage

### 1. Cross-Platform .NET Development (Web APIs, Microservices, Console)

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

## Structure

```
nix-dotnet-template/
├── flake.nix             # Flake entrypoint exposing default and windows devShells
├── nix/
│   ├── builder.nix       # DRY devShell constructor
│   ├── dotnet-wrapper.nix# Transparent dotnet CLI wrapper script
│   └── wine-env.nix      # Isolated Wine prefix manager
├── .envrc                # direnv integration
└── .github/
    └── workflows/        # Reusable GitHub Actions workflow
```
