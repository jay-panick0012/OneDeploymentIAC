###############################################################################
# scripts/new-region.ps1
#
# Scaffolds a new environments/<env>/<cloud>/<region>/ root by copying an
# existing region directory of the same environment+cloud (so it inherits the
# right tier sizing) and rewriting the region/location and backend key. It
# does NOT pick a region_index for you -- open .github/environments.json,
# find the highest region_index in use across the WHOLE file, and pass the
# next integer. Reusing an index will collide CIDR ranges with another
# region's VPC/VNet.
#
# Usage:
#   scripts/new-region.ps1 -Environment <env> -Cloud <cloud> -NewRegion <region> -RegionIndex <n>
#
# Example:
#   scripts/new-region.ps1 -Environment production -Cloud aws -NewRegion ap-south-1 -RegionIndex 5
###############################################################################

param(
  [Parameter(Mandatory = $true)][string]$Environment,
  [Parameter(Mandatory = $true)][ValidateSet("aws", "azure", "gcp")][string]$Cloud,
  [Parameter(Mandatory = $true)][string]$NewRegion,
  [Parameter(Mandatory = $true)][int]$RegionIndex
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$envCloudDir = Join-Path $repoRoot "environments\$Environment\$Cloud"

if (-not (Test-Path $envCloudDir)) {
  throw "$envCloudDir does not exist -- is '$Environment'/'$Cloud' correct?"
}

$templateDir = Get-ChildItem -Path $envCloudDir -Directory | Select-Object -First 1
if (-not $templateDir) {
  throw "no existing region directory to copy under $envCloudDir"
}
$templateRegion = $templateDir.Name

$targetDir = Join-Path $envCloudDir $NewRegion
if (Test-Path $targetDir) {
  throw "$targetDir already exists"
}

Write-Host "Copying $envCloudDir\$templateRegion -> $targetDir"
Copy-Item -Path $templateDir.FullName -Destination $targetDir -Recurse

foreach ($file in @("terraform.tfvars", "variables.tf")) {
  $path = Join-Path $targetDir $file
  $content = Get-Content $path -Raw
  $content = $content -replace [regex]::Escape($templateRegion), $NewRegion
  $content = $content -replace "region_index\s*=\s*\d+", "region_index = $RegionIndex"
  Set-Content -Path $path -Value $content -Encoding utf8 -NoNewline
}

$backendPath = Join-Path $targetDir "backend.hcl"
$backendContent = Get-Content $backendPath -Raw
$backendContent = $backendContent -replace "environments/$Environment/$Cloud/$templateRegion", "environments/$Environment/$Cloud/$NewRegion"
Set-Content -Path $backendPath -Value $backendContent -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "Created $targetDir from the $templateRegion template."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Double-check $targetDir\terraform.tfvars and backend.hcl -- region"
Write-Host "     names sometimes appear inside other strings (e.g. a bucket name) that"
Write-Host "     this script's find/replace may not catch."
Write-Host "  2. Add this region to .github/environments.json under"
Write-Host "     `"$Environment`" -> `"$Cloud`", with the same region_index ($RegionIndex)."
Write-Host "  3. cd $targetDir; terraform init -backend-config=backend.hcl; terraform plan -var-file=terraform.tfvars"
