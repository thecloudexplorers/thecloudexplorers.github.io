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

The documentation uses the [SingulinkFX](https://github.com/Singulink/SingulinkFX) theme (v3.0.4), which provides:

- Fully responsive design for all device sizes
- Clean, modern interface familiar to Microsoft .NET documentation users
- Collapsible navigation with support for 4 levels of hierarchy
- Efficient table rendering (empty columns are automatically removed)
- Search functionality
- Mobile-friendly layout
- Bootstrap Icons integration
- Configurable colors and layout options

## Contributing

To add or modify documentation:

1. Edit markdown files in the `docs/` directory
2. Update `docs/toc.yml` if adding new pages
3. Test locally using `docfx serve`
4. Commit and push changes

The site will automatically rebuild and deploy via GitHub Actions.

### Adding Diagrams

To include diagrams in your documentation:

1. **Place Draw.io files** in the `diagrams` directory within your documentation section
   - Example: `docs/architecture/cloud-reference-architecture/diagrams/cloud-reference-architecture.drawio`

   ![Draw.io file location](docs/images/drawio-and-images-location.png)

2. **Build process** - The build script automatically:
   - Detects `.drawio` files in the `diagrams` directory
   - Creates an `images` folder within the same `diagrams` directory
   - Generates PNG images from your Draw.io diagrams
   - **Image names are based on Draw.io tab names**: Each tab in your Draw.io file becomes a separate PNG image with the tab name as the filename (converted to lowercase with spaces replaced by hyphens)

   ![drawio Tab Name](docs/images/drawio-tab-name.png)

3. **Reference in markdown** - Add the diagram to your markdown file using the relative path: `diagrams/images/<tab-name>.png`
   
   ![drawio Tab Name](docs/images/drawio-file-name.png)

**Example:**

For a page at `docs/architecture/cloud-reference-architecture/introduction.md`:

1. Create your diagram in `docs/architecture/cloud-reference-architecture/diagrams/cloud-reference-architecture.drawio`
2. Add a tab in Draw.io named "Cloud Adoption Phases"
3. The build script generates: `docs/architecture/cloud-reference-architecture/diagrams/images/cloud-adoption-phases.png`
4. Reference it in your markdown:

```markdown
![Cloud Adoption Phases](diagrams/images/cloud-adoption-phases.png)
```

**Note:** 
- The `diagrams/images/` folder is auto-generated during the build process—you don't need to create it manually
- Each tab in your Draw.io file generates a separate PNG image with the tab name as the filename

## License

© 2025 The Cloud Explorers. All rights reserved.
