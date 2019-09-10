
if( $IsWindows -and [Environment]::Is64BitOperatingSystem -and [Environment]::Is64BitProcess ) 
{
    . (Join-Path -Path $functionRoot -ChildPath 'Initialize-Lcm.ps1')
}
