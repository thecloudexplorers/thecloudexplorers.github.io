# -------------------------------------------------------------
# Generate PDFs only for TOCs where "pdf: true" exists
# -------------------------------------------------------------

param (
    [string]$MarkdownRoot = "docs", # Parameterized markdown root directory
    [string]$OutputRoot = "_site"   # Parameterized output root directory
)

# Root folder where your docs live:
$root = Join-Path (Get-Location).Path $MarkdownRoot

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

        Write-Host "   Generating PDF: $outputPdf"

        # Call pandoc
        pandoc $orderedFiles -s -o $outputPdf --pdf-engine=wkhtmltopdf

        Write-Host "   ✔ PDF created: $outputPdf." -ForegroundColor Green

        Write-Host "   Generating Word: $outputDocx"

        # Call pandoc
        pandoc $orderedFiles -s -o $outputDocx

        Write-Host "   ✔ Word created: $outputDocx." -ForegroundColor Green
    }
    else {
        Write-Host " → pdf: true not found. Skipping." -ForegroundColor DarkGray
    }

    Write-Host ""
}
