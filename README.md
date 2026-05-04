# Transparent Ruler

A transparent, always-on-top ruler for precise on-screen measurements. Built with SwiftUI for macOS.

## Features

- **Always On Top**: Stays above all other windows for easy reference
- **Draggable**: Move the ruler anywhere on your screen by clicking and dragging
- **Configurable Units**: Switch between pixels, millimeters, centimeters, and inches
- **Adjustable Transparency**: Control the opacity of the ruler via the menu bar
- **Color Customization**: Choose from preset colors or create custom colors with HSB controls

## Requirements

- macOS 12.0 or later
- Swift 5.7 or later

## Building

### Debug Build
```bash
swift build
```

### Release Build (Optimized, All Architectures)
```bash
swift build --configuration release
```

## Production Deployment

Use the automated deployment script to build and package the app with icon support:

```bash
./deploy.zsh
```

This script:
- Builds the release version
- Creates the proper app bundle structure
- Copies the executable
- Includes the icon and Info.plist
- Generates output ready for distribution

## Icon Setup

### Option 1: Generate Icon Automatically (Python)

If you have Python 3 with Pillow installed:

```bash
./generate-icon.py
./create-icon.zsh icon.png
mkdir -p Resources
cp icon.icns Resources/AppIcon.icns
./deploy.zsh
```

### Option 2: Manual Icon Creation

1. Create or prepare a 512x512 PNG image (transparent background recommended)
2. Convert to .icns format:
   ```bash
   ./create-icon.zsh your-icon.png
   ```
3. Copy to Resources:
   ```bash
   mkdir -p Resources
   cp icon.icns Resources/AppIcon.icns
   ```
4. Deploy:
   ```bash
   ./deploy.zsh
   ```

## Running

### From Source (Debug)
```bash
swift run TransparentRuler
```

### From App Bundle (Production)
```bash
open TransparentRuler.app
```

Or double-click `TransparentRuler.app` in Finder.

### Install to Applications
```bash
mv TransparentRuler.app ~/Applications/
```

## Usage

Once running, interact with the ruler via the menu bar:

- **About**: View app information
- **Units**: Switch between pt (pixels), mm, cm, or inches
- **Transparency**: Adjust the ruler's opacity (0-100%)
- **Quit**: Close the application

Right-click on the ruler to access the color picker and customize its appearance.

## Project Structure

```
TransparentRuler/
├── Package.swift
├── README.md
├── deploy.zsh               # Production deployment script
├── create-icon.zsh          # Icon converter utility
├── generate-icon.py         # Simple icon generator
├── Resources/               # Icon resources
│   └── AppIcon.icns        # App icon (generated)
└── Sources/
    └── TransparentRuler/
        └── main.swift
```

## Author

© 2026 Paulo Morais Nascimento