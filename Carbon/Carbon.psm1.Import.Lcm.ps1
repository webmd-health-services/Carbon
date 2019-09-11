
if( $IsWindows -and [Environment]::Is64BitOperatingSystem -and [Environment]::Is64BitProcess ) 
{
    Write-Timing ('Dot-sourcing Initialize-Lcm.ps1')
    . (Join-Path -Path $functionRoot -ChildPath 'Initialize-Lcm.ps1')
}
