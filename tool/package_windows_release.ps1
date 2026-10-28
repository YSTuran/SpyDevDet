[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$releaseDirectory = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$distributionDirectory = Join-Path $projectRoot 'build\distributions'

$versionLine = Select-String -LiteralPath $pubspecPath -Pattern '^version:\s*(\S+)\s*$' |
    Select-Object -First 1
if ($null -eq $versionLine) {
    throw 'pubspec.yaml içinde sürüm bilgisi bulunamadı.'
}

$version = $versionLine.Matches[0].Groups[1].Value.Replace('+', '-build')
$archivePath = Join-Path $distributionDirectory "spydevdet-windows-$version-x64.zip"
$checksumPath = "$archivePath.sha256"

if (-not $SkipBuild) {
    Push-Location $projectRoot
    try {
        & flutter build windows --release --no-pub
        if ($LASTEXITCODE -ne 0) {
            throw "Windows release derlemesi başarısız oldu: $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Windows release klasörü bulunamadı: $releaseDirectory"
}

New-Item -ItemType Directory -Path $distributionDirectory -Force | Out-Null
$packageItems = @(
    Get-ChildItem -LiteralPath $releaseDirectory |
        Where-Object { $_.Name -ne 'network_adapter_classifier_test.exe' }
)
if ($packageItems.Count -eq 0) {
    throw 'Windows release klasöründe paketlenecek dosya bulunamadı.'
}
Compress-Archive -Path $packageItems.FullName -DestinationPath $archivePath -Force

$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumLine = "$hash  $(Split-Path -Leaf $archivePath)"
Set-Content -LiteralPath $checksumPath -Value $checksumLine -Encoding ascii

Write-Output "Windows release paketi: $archivePath"
Write-Output "SHA-256: $hash"
