# -------------------------------------------------------------
# Build Script: Export Draw.io diagrams, Build DocFX, Generate PDFs/Word
# -------------------------------------------------------------

param (
    [string]$MarkdownRoot = "docs",     # Parameterized markdown root directory
    [string]$OutputRoot = "_site",      # Parameterized output root directory
    [string]$DocfxConfig = "docfx.json" # DocFX configuration file
)

# Root folder where your docs live:
$root = Join-Path (Get-Location).Path $MarkdownRoot

Write-Host ""
Write-Host "=======================================" -ForegroundColor Magenta
Write-Host "   Documentation Build Script" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta
Write-Host ""

# -------------------------------------------------------------
# Step 1: Export Draw.io diagrams to images
# -------------------------------------------------------------

Write-Host "=== Step 1: Exporting Draw.io Diagrams ===" -ForegroundColor Cyan
Write-Host ""

# Find all .drawio files recursively
$drawioFiles = Get-ChildItem -Path $root -Filter "*.drawio" -Recurse

if ($drawioFiles.Count -eq 0) {
    Write-Host "No Draw.io files found." -ForegroundColor Yellow
    Write-Host ""
} else {
    foreach ($drawioFile in $drawioFiles) {
        Write-Host "Processing: $($drawioFile.FullName)" -ForegroundColor White
        
        # Determine output directory (sibling 'images' folder)
        $diagramDir = $drawioFile.Directory.FullName
        $imagesDir = Join-Path $diagramDir "images"
        
        # Create images directory if it doesn't exist
        if (!(Test-Path -Path $imagesDir)) {
            New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null
            Write-Host "  Created images directory: $imagesDir" -ForegroundColor Green
        }
        
        # Check if draw.io CLI is available
        $drawioCmd = $null
        if (Get-Command "draw.io" -ErrorAction SilentlyContinue) {
            $drawioCmd = "draw.io"
        } elseif (Get-Command "drawio" -ErrorAction SilentlyContinue) {
            $drawioCmd = "drawio"
        } elseif (Test-Path "C:\Program Files\draw.io\draw.io.exe") {
            $drawioCmd = "C:\Program Files\draw.io\draw.io.exe"
        } elseif (Test-Path "${env:LOCALAPPDATA}\Programs\draw.io\draw.io.exe") {
            $drawioCmd = "${env:LOCALAPPDATA}\Programs\draw.io\draw.io.exe"
        }
        
        if ($drawioCmd) {
            Write-Host "  Using draw.io CLI: $drawioCmd" -ForegroundColor DarkGray
            
            # Read the XML to get diagram names and count pages
            [xml]$xmlContent = Get-Content $drawioFile.FullName
            $diagrams = @()
            
            # Get all diagram elements
            if ($xmlContent.mxfile.diagram) {
                if ($xmlContent.mxfile.diagram -is [System.Array]) {
                    $diagrams = $xmlContent.mxfile.diagram
                } else {
                    $diagrams = @($xmlContent.mxfile.diagram)
                }
            }
            
            $pageCount = $diagrams.Count
            Write-Host "  Found $pageCount page(s) in diagram" -ForegroundColor DarkGray
            
            # Export each page individually
            $exportedCount = 0
            
            for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
                # Get the diagram name and sanitize it for filename
                $diagramName = $diagrams[$pageIndex].name
                if ([string]::IsNullOrWhiteSpace($diagramName)) {
                    $diagramName = "page-$pageIndex"
                } else {
                    # Sanitize filename: replace invalid characters with hyphens
                    $diagramName = $diagramName -replace '[\\/:*?"<>|]', '-'
                    $diagramName = $diagramName -replace '\s+', '-'
                    $diagramName = $diagramName.ToLower()
                }
                
                $outputFile = Join-Path $imagesDir "$diagramName.png"
                
                try {
                    # Use --page-index to export specific page
                    & $drawioCmd --export --format png --page-index $pageIndex --output $outputFile $drawioFile.FullName 2>&1 | Out-Null
                    
                    if (Test-Path $outputFile) {
                        $exportedCount++
                        Write-Host "    ✔ Page $pageIndex ('$($diagrams[$pageIndex].name)') exported: $(Split-Path $outputFile -Leaf)" -ForegroundColor Green
                    } else {
                        Write-Host "    ✘ Page $pageIndex export failed (file not created)" -ForegroundColor Red
                    }
                } catch {
                    Write-Host "    ✘ Error exporting page ${pageIndex}: $_" -ForegroundColor Red
                }
            }
            
            if ($exportedCount -gt 0) {
                Write-Host "  ✔ Successfully exported $exportedCount/$pageCount diagram(s)" -ForegroundColor Green
            } else {
                Write-Host "  ✘ No diagrams were exported" -ForegroundColor Red
            }
        } else {
            Write-Host "  ⚠ draw.io CLI not found. Skipping diagram export." -ForegroundColor Yellow
            Write-Host "    Install from: https://github.com/jgraph/drawio-desktop/releases" -ForegroundColor DarkGray
        }
        
        Write-Host ""
    }
}

# -------------------------------------------------------------
# Step 2: Build DocFX site
# -------------------------------------------------------------

Write-Host "=== Step 2: Building DocFX Site ===" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $DocfxConfig)) {
    Write-Host "DocFX configuration file not found: $DocfxConfig" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Running: docfx build $DocfxConfig" -ForegroundColor White
    docfx build $DocfxConfig
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✔ DocFX build completed successfully" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "✘ DocFX build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        exit $LASTEXITCODE
    }
} catch {
    Write-Host ""
    Write-Host "✘ Error running DocFX: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# -------------------------------------------------------------
# Step 3: Generate PDF and Word documents
# -------------------------------------------------------------

Write-Host "=== Step 3: Generating PDF and Word Documents ===" -ForegroundColor Cyan
Write-Host ""

# Find all toc.yml files recursively
$tocs = Get-ChildItem -Path $root -Filter "toc.yml" -Recurse

foreach ($toc in $tocs) {

    Write-Host "Checking: $($toc.FullName)" -ForegroundColor White

    # Read YAML as text
    $yaml = Get-Content $toc.FullName -Raw

    # Check if pdf: true exists anywhere
    if ($yaml -match "pdf:\s*true") {
        
        Write-Host " → pdf: true found. Processing…" -ForegroundColor Green

        # Extract ordered href: entries
        $files = [regex]::Matches($yaml, 'href:\s*(.+)') |
            ForEach-Object {
            $match = $_.Groups[1].Value.Trim()
            $match.Trim('"', "'")
            } |
            Where-Object { $_ -like '*.md' }

        if ($files.Count -eq 0) {
            Write-Host "   No markdown files found in href: order. Skipping." -ForegroundColor Yellow
            Write-Host ""
            continue
        }

        # Convert relative paths relative to the TOC's folder
        $orderedFiles = $files | ForEach-Object {
            Join-Path $toc.Directory.FullName $_
        }

        # Output directory for this TOC
        $relativePath = $toc.Directory.FullName.Substring($root.Length).TrimStart("\\")
        $outputDir = Join-Path $OutputRoot $relativePath
        if (!(Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
        }

        # Output PDF and Word names (use section name)
        $sectionName = $toc.Directory.Name
        $pdfName = "$sectionName.pdf"
        $docxName = "$sectionName.docx"
        $outputPdf = Join-Path $outputDir $pdfName
        $outputDocx = Join-Path $outputDir $docxName

        # Create temp directory for modified markdown files with absolute image paths
        # Use cross-platform temp directory
        $tempBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
        $tempDir = Join-Path $tempBase "pandoc-temp-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        $tempFiles = @()

        try {
            # Set Puppeteer executable path for mmdc (mermaid-cli)
            # This ensures mmdc can find Chromium on different systems
            if ($env:PUPPETEER_EXECUTABLE_PATH) {
                Write-Host "   Using Puppeteer executable: $env:PUPPETEER_EXECUTABLE_PATH" -ForegroundColor DarkGray
            } elseif (Test-Path "/usr/bin/chromium-browser") {
                $env:PUPPETEER_EXECUTABLE_PATH = "/usr/bin/chromium-browser"
                Write-Host "   Set Puppeteer executable to: /usr/bin/chromium-browser" -ForegroundColor DarkGray
            } elseif (Test-Path "/usr/bin/chromium") {
                $env:PUPPETEER_EXECUTABLE_PATH = "/usr/bin/chromium"
                Write-Host "   Set Puppeteer executable to: /usr/bin/chromium" -ForegroundColor DarkGray
            }
            
            # Create mermaid images directory
            $mermaidImagesDir = Join-Path $tempDir "mermaid-images"
            New-Item -ItemType Directory -Force -Path $mermaidImagesDir | Out-Null
            
            # Counter for Mermaid diagrams
            $mermaidCounter = 0
            
            # Process each markdown file to convert relative image paths to absolute paths
            # and convert Mermaid diagrams to images
            foreach ($mdFile in $orderedFiles) {
                $content = Get-Content $mdFile -Raw
                $basePath = Split-Path $mdFile -Parent
                
                # Replace relative image paths with absolute paths
                # Match: ![alt text](diagrams/images/filename.png)
                $pattern = '!\[([^\]]*)\]\(diagrams/images/([^\)]+)\)'
                $content = [regex]::Replace($content, $pattern, {
                    param($match)
                    $altText = $match.Groups[1].Value
                    $imageName = $match.Groups[2].Value
                    $absolutePath = Join-Path $basePath "diagrams\images\$imageName"
                    # Convert backslashes to forward slashes for Pandoc/wkhtmltopdf
                    $absolutePath = $absolutePath -replace '\\', '/'
                    "![$altText](file:///$absolutePath)"
                })
                
                # Process Mermaid code blocks
                # Match: ```mermaid ... ```
                $mermaidPattern = '(?s)```mermaid\s*\n(.*?)\n```'
                $content = [regex]::Replace($content, $mermaidPattern, {
                    param($match)
                    $mermaidCode = $match.Groups[1].Value
                    $mermaidCounter++
                    
                    # Create temp mermaid file
                    $mermaidFile = Join-Path $tempDir "mermaid-$mermaidCounter.mmd"
                    $mermaidCode | Out-File -FilePath $mermaidFile -Encoding UTF8 -NoNewline
                    
                    # Output image path
                    $mermaidImage = Join-Path $mermaidImagesDir "mermaid-diagram-$mermaidCounter.png"
                    
                    # Check if mmdc is available
                    $mmdcCmd = Get-Command "mmdc" -ErrorAction SilentlyContinue
                    if ($mmdcCmd) {
                        try {
                            # Convert Mermaid to PNG
                            & mmdc -i $mermaidFile -o $mermaidImage -b transparent 2>&1 | Out-Null
                            
                            if (Test-Path $mermaidImage) {
                                # Convert to forward slashes for Pandoc
                                $imagePathForPandoc = $mermaidImage -replace '\\', '/'
                                Write-Host "      ✔ Converted Mermaid diagram $mermaidCounter" -ForegroundColor Green
                                # Return image markdown
                                return "![Mermaid Diagram](file:///$imagePathForPandoc)"
                            } else {
                                Write-Host "      ✘ Failed to generate Mermaid diagram $mermaidCounter" -ForegroundColor Red
                                return $match.Value
                            }
                        } catch {
                            Write-Host "      ✘ Error converting Mermaid diagram $mermaidCounter : $_" -ForegroundColor Red
                            return $match.Value
                        }
                    } else {
                        Write-Host "      ⚠ mmdc not found, keeping Mermaid code block $mermaidCounter" -ForegroundColor Yellow
                        return $match.Value
                    }
                })
                
                # Save to temp file
                $tempFile = Join-Path $tempDir (Split-Path $mdFile -Leaf)
                $content | Out-File -FilePath $tempFile -Encoding UTF8
                $tempFiles += $tempFile
            }

            Write-Host "   Generating PDF: $outputPdf"
            
            # Generate PDF using temp files with absolute paths
            pandoc $tempFiles -s -o $outputPdf --pdf-engine=wkhtmltopdf
            Write-Host "   ✔ PDF created: $outputPdf" -ForegroundColor Green

            Write-Host "   Generating Word: $outputDocx"
            
            # Generate Word using temp files with absolute paths
            pandoc $tempFiles -s -o $outputDocx
            Write-Host "   ✔ Word created: $outputDocx" -ForegroundColor Green
        }
        catch {
            Write-Host "   ✘ Error creating documents: $_" -ForegroundColor Red
        }
        finally {
            # Clean up temp directory
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
    }
    else {
        Write-Host " → pdf: true not found. Skipping." -ForegroundColor DarkGray
    }

    Write-Host ""
}

# -------------------------------------------------------------
# Build Complete
# -------------------------------------------------------------

Write-Host "=======================================" -ForegroundColor Magenta
Write-Host "   Build Complete!" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Output directory: $OutputRoot" -ForegroundColor Green
Write-Host ""
