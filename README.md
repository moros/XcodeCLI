# XcodeCLI

A command-line tool for managing Swift packages in Xcode projects and workspaces. XcodeCLI provides seamless integration between local Swift packages and Xcode projects, allowing developers to easily attach, detach, and manage package dependencies.

## Overview

XcodeCLI is designed to solve the common workflow challenge of switching between local development of Swift packages and using remote package dependencies in Xcode projects. It provides a simple, command-line interface to:

- **Attach** local Swift packages to Xcode projects/workspaces for development
- **Detach** local packages and restore remote package references
- **Link** packages to your project configuration for easy management
- **Delink** packages from your project configuration
- **Initialize** project configurations for new or existing Xcode projects

## Features

- 🔄 **Seamless Package Switching**: Easily switch between local and remote package references
- 📁 **Project/Workspace Support**: Works with both individual Xcode projects and workspaces
- 🎯 **Smart Auto-Discovery**: Automatically finds Xcode projects in your current directory
- 💾 **State Preservation**: Remembers remote package references when switching to local packages
- 📝 **Configuration Management**: Simple configuration files for project settings
- 🛠 **Command-Line Interface**: Clean, intuitive CLI with helpful error messages

## Installation

### Prerequisites

- macOS 10.15 or later
- Xcode 16.0 or later
- Swift 6.1 or later

### Building from Source

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd XcodeCLI
   ```

2. Build the project:
   ```bash
   xcodebuild -project XcodeCLI.xcodeproj -scheme XcodeCLI -configuration Release
   ```

3. Find and install the binary (optional):
   ```bash
   # Find the built binary (searches in Xcode's default build locations)
   find ~/Library/Developer/Xcode/DerivedData -name "XcodeCLI" -type f 2>/dev/null
   
   # Install it (replace with the actual path from the find command)
   # You may need sudo if /usr/local/bin requires elevated permissions
   sudo cp build/Release/XcodeCLI /usr/local/bin/xcodeCLI
   ```

## Usage

### Command Overview

The main command is `xcodeCLI` with the following subcommands:

- `init` - Initialize a new project configuration
- `link` - Add a Swift package to your project configuration
- `delink` - Remove a Swift package from your project configuration
- `attach` - Attach local packages to your Xcode project/workspace
- `detach` - Detach local packages and restore remote references

### Global Options

All commands support these global options:

- `-c, --config <path>` - Path to configuration file or directory (defaults to `.xcodecli` directory in current directory)
- `-w, --workdir <path>` - Working directory (defaults to current directory)

### Getting Started

#### 1. Initialize Your Project

Start by initializing a configuration for your Xcode project:

```bash
# For a project in the current directory
xcodeCLI init --project MyApp.xcodeproj

# For a workspace
xcodeCLI init --workspace MyApp.xcworkspace

# For auto-discovery (will find .xcodeproj or .xcworkspace automatically)
xcodeCLI init
```

This creates a `.xcodecli` directory with a `config.plist` file containing your project settings.

#### 2. Link Your Packages

Add Swift packages to your configuration:

```bash
# Link a package from a specific path
xcodeCLI link /path/to/MyPackage

# Link the package in the current directory
xcodeCLI link --config /path/to/project

# Link multiple packages
xcodeCLI link Package1
xcodeCLI link Package2
```

#### 3. Attach Packages for Development

Switch to local package references for development:

```bash
# Attach all linked packages
xcodeCLI attach

# Attach with custom config path
xcodeCLI attach --config /path/to/project
```

#### 4. Detach Packages

Switch back to remote package references:

```bash
# Detach all local packages
xcodeCLI detach

# Detach with custom config path
xcodeCLI detach --config /path/to/project
```

### Configuration File Format

The configuration is stored in a `.xcodecli/config.plist` file with the following structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Project</key>
    <string>path/to/MyApp.xcodeproj</string>
    <key>Workspace</key>
    <string>path/to/MyApp.xcworkspace</string>
</dict>
</plist>
```

Package locations are stored in a separate `packages.plist` file, with one package path per line.

## Workflow Examples

### Typical Development Workflow

1. **Start with remote packages** in your Xcode project
2. **Initialize** XcodeCLI configuration: `xcodeCLI init`
3. **Link** your local package: `xcodeCLI link /path/to/MyPackage`
4. **Attach** for development: `xcodeCLI attach`
5. **Make changes** to your local package
6. **Test** in your main project
7. **Detach** when done: `xcodeCLI detach`
8. **Commit and push** your package changes

### Multi-Package Development

```bash
# Set up multiple packages
xcodeCLI link /path/to/CorePackage
xcodeCLI link /path/to/UIPackage
xcodeCLI link /path/to/NetworkPackage

# Attach all for development
xcodeCLI attach

# Work on all packages simultaneously
# ... make changes ...

# Detach all when done
xcodeCLI detach
```

### Workspace Support

XcodeCLI works seamlessly with Xcode workspaces:

```bash
# Initialize with workspace
xcodeCLI init --workspace MyApp.xcworkspace

# Attach packages to all projects in workspace
xcodeCLI attach
```

## Architecture

The project consists of three main components:

1. **XcodeCLI** - The main command-line interface built with ArgumentParser
2. **CLI** - Core library containing configuration management and package operations
3. **XcodeProj** - Library for reading and writing Xcode project files

### Key Components

- **ConfigurationManager** - Handles project configuration files
- **PackageLocation** - Manages package path tracking
- **PackageStateManager** - Preserves remote package state during local development
- **XcodeProjectFinder** - Auto-discovers Xcode projects and workspaces

## Error Handling

XcodeCLI provides clear error messages for common issues:

- Missing configuration files
- Invalid project/workspace paths
- Package parsing errors
- Xcode project file corruption
- Permission issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

[Add your license information here]

## Support

For issues and questions:

1. Check the error messages for guidance
2. Review the configuration file format
3. Ensure your Xcode project is valid
4. Verify package paths are correct

## Troubleshooting

### Common Issues

**"Configuration file not found"**
- Run `xcodeCLI init` to create the configuration
- Check that you're in the correct directory

**"Package not found in configuration"**
- Use `xcodeCLI link` to add the package first
- Verify the package path is correct

**"Xcode project not found"**
- Ensure the project path in config.plist is correct
- Use `xcodeCLI init --project` to set the correct path

**"Permission denied"**
- Check file permissions on the Xcode project
- Ensure you have write access to the project directory 