param(
    [string]$OutputPath = "DeathFeed.zip"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tocPath = Join-Path $root "DeathFeed.toc"
$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("DeathFeedPackage_" + [System.Guid]::NewGuid().ToString("N"))
$addonRoot = Join-Path $stagingRoot "DeathFeed"
$zipPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $root $OutputPath }

New-Item -ItemType Directory -Path $addonRoot | Out-Null

$files = @("DeathFeed.toc")
$files += Get-Content $tocPath |
    ForEach-Object { $_.Trim() } |
    Where-Object {
        $_ -ne "" -and
        -not $_.StartsWith("#") -and
        -not $_.StartsWith("##")
    }

foreach ($relativePath in $files) {
    $source = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing package file: $relativePath"
    }

    $destination = Join-Path $addonRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
    }

    Copy-Item -LiteralPath $source -Destination $destination
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath
}

Compress-Archive -Path $addonRoot -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $stagingRoot -Recurse

Write-Host "Created $zipPath"
