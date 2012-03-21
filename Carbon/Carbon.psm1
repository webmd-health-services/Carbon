
$CarbonBinDir = Join-Path $PSScriptRoot bin -Resolve

Get-Item (Join-Path $PSScriptRoot *.ps1) | ForEach-Object {
    Write-Verbose "Importing sub-module $(Split-Path -Leaf $_)."
    . $_
}

$CarbonImported = $true

Export-ModuleMember -Function * -Cmdlet * -Variable CarbonImported -Alias *
