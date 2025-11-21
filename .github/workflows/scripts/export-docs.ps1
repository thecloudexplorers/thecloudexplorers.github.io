# -------------------------------------------------------------
# Generate PDFs only for TOCs where "pdf: true" exists
# Export Draw.io diagrams to PNG images
# -------------------------------------------------------------

param (
    [string]$MarkdownRoot = "docs", # Parameterized markdown root directory
    [string]$OutputRoot = "_site"   # Parameterized output root directory
)

# Root folder where your docs live:
$root = Join-Path (Get-Location).Path $MarkdownRoot

# -------------------------------------------------------------
# Export Draw.io diagrams to images
# -------------------------------------------------------------

Write-Host "=== Exporting Draw.io Diagrams ===" -ForegroundColor Magenta

# Find all .drawio files recursively
$drawioFiles = Get-ChildItem -Path $root -Filter "*.drawio" -Recurse

foreach ($drawioFile in $drawioFiles) {
    Write-Host "Processing: $($drawioFile.FullName)" -ForegroundColor Cyan
    
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
        Write-Host "  Using draw.io CLI: $drawioCmd" -ForegroundColor Yellow
        
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
        Write-Host "  Found $pageCount page(s) in diagram" -ForegroundColor Cyan
        
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
            Write-Host "  ✔ Successfully exported $exportedCount/$pageCount diagram(s) to: $imagesDir" -ForegroundColor Green
        } else {
            Write-Host "  ✘ No diagrams were exported" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠ draw.io CLI not found. Skipping diagram export." -ForegroundColor Yellow
        Write-Host "    Install draw.io desktop from: https://github.com/jgraph/drawio-desktop/releases" -ForegroundColor DarkGray
        Write-Host "    Or use: choco install drawio" -ForegroundColor DarkGray
    }
    
    Write-Host ""
}

Write-Host "=== Processing TOC files for PDF generation ===" -ForegroundColor Magenta
Write-Host ""

# Find all toc.yml files recursively
$tocs = Get-ChildItem -Path $root -Filter "toc.yml" -Recurse

foreach ($toc in $tocs) {

    Write-Host "Checking: $($toc.FullName)" -ForegroundColor Cyan

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
        $tempDir = Join-Path $env:TEMP "pandoc-temp-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        $tempFiles = @()

        try {
            # Process each markdown file to convert relative image paths to absolute paths
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
                
                # Save to temp file
                $tempFile = Join-Path $tempDir (Split-Path $mdFile -Leaf)
                $content | Out-File -FilePath $tempFile -Encoding UTF8
                $tempFiles += $tempFile
            }

            Write-Host "   Generating PDF: $outputPdf"
            
            # Generate PDF using temp files with absolute paths
            pandoc $tempFiles -s -o $outputPdf --pdf-engine=wkhtmltopdf
            Write-Host "   ✔ PDF created: $outputPdf." -ForegroundColor Green

            Write-Host "   Generating Word: $outputDocx"
            
            # Generate Word using temp files with absolute paths
            pandoc $tempFiles -s -o $outputDocx
            Write-Host "   ✔ Word created: $outputDocx." -ForegroundColor Green
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
