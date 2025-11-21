# The Cloud Explorers Documentation

This repository contains the documentation for The Cloud Explorers, built with [DocFX](https://dotnet.github.io/docfx/) and deployed to GitHub Pages.

## Building the Documentation

### Prerequisites

- [.NET SDK 8.0 or later](https://dotnet.microsoft.com/download)
- DocFX (installed automatically via dotnet tool)

### Build Instructions

1. Install DocFX:
   ```bash
   dotnet tool install -g docfx
   ```

2. Build the documentation:
   ```bash
   docfx build docfx.json
   ```

3. Serve locally for preview:
   ```bash
   docfx serve _site
   ```

4. Open your browser to http://localhost:8080

## Documentation Structure

- `docs/` - Documentation markdown files
- `docs/toc.yml` - Table of contents configuration
- `docfx.json` - DocFX configuration file
- `.github/workflows/docfx.yml` - GitHub Actions workflow for deployment

## Theme

The documentation uses DocFX's modern template, which provides:
- Responsive design
- Dark/light theme toggle
- Collapsible navigation menus
- Breadcrumb navigation
- Search functionality
- Mobile-friendly layout

## Contributing

To add or modify documentation:

1. Edit markdown files in the `docs/` directory
2. Update `docs/toc.yml` if adding new pages
3. Test locally using `docfx serve`
4. Commit and push changes

The site will automatically rebuild and deploy via GitHub Actions.

## License

© 2024 The Cloud Explorers. All rights reserved.
