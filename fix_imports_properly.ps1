# Fix import paths - they should be ../../features/ not ../features/
Write-Host "Fixing import paths..." -ForegroundColor Green

$files = Get-ChildItem -Path "lib/core/navigation" -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Fix the path - should be ../../features/ not ../features/
    $content = $content -replace "import '\.\./features/", "import '../../features/"
    
    Set-Content $file.FullName $content -NoNewline
    Write-Host "Fixed: $($file.Name)" -ForegroundColor Yellow
}

# Fix main.dart imports
$mainFile = "lib/main.dart"
$content = Get-Content $mainFile -Raw

# Update main.dart imports to use correct paths
$content = $content -replace "import 'features/", "import 'features/owner/"

Set-Content $mainFile $content -NoNewline
Write-Host "Fixed: main.dart" -ForegroundColor Yellow

Write-Host "`nImport paths fixed!" -ForegroundColor Green
