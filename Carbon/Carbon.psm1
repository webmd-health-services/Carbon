
$Win32OperatingSystem = Get-WmiObject Win32_OperatingSystem
$Is64BitOS = $Win32OperatingSystem.OSArchitecture -eq '64-bit'
$Is32BitOS = -not $Is64BitOS
$CarbonBinDir = Join-Path $PSScriptRoot bin -Resolve

Get-Item (Join-Path $PSScriptRoot *.ps1) | ForEach-Object {
    Write-Verbose "Importing sub-module $(Split-Path -Leaf $_)."
    . $_
}

$CarbonImported = $true

Export-ModuleMember -Function * -Cmdlet * -Variable CarbonImported -Alias *
