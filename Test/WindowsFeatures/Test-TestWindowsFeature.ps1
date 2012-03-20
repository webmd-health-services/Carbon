
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}


if( (Get-Command servermanagercmd.exe -ErrorAction SilentlyContinue) )
{
    function Test-ShouldDetectInstalledFeature
    {
        $installedFeatures = servermanagercmd.exe -q
        foreach( $line in $installedFeatures )
        {
            if( $line -match 'X\].*\[(.+?)\]$' )
            {
                $featureName = $matches[1]
                Assert-NotEmpty $featureName
                Assert-True (Test-WindowsFeature -Name $featureName)
                break
            }
        }
    }
    
    function Test-ShouldDetectUninstalledFeature
    {
        $installedFeatures = servermanagercmd.exe -q
        foreach( $line in $installedFeatures )
        {
            if( $line -match ' \].*\[(.+?)\]$' )
            {
                $featureName = $matches[1]
                Assert-NotEmpty $featureName
                Assert-False (Test-WindowsFeature -Name $featureName)
                break
            }
        }
    }
}
elseif( (Get-WmiObject -Class Win32_OptionalFeatures -ErrorAction SilentlyContinue) )
{
    function Test-ShouldDetectInstalledFeature
    {
        $components = Get-WmiObject -Query "select Name,InstallState from Win32_OptionalFeature where InstallState=1"
        foreach( $component in $components )
        {
            $installed = Test-WindowsFeatures -Name $component.Name
            Assert-True $installed "for component '$($component.Name)'"
        }
    }
    
    function Test-ShouldDetectUninstalledFeature
    {
        $components = Get-WmiObject -Query "select Name,InstallState from Win32_OptionalFeature where InstallState=2"
        foreach( $component in $components )
        {
            $installed = Test-WindowsFeatures -Name $component.Name
            Assert-False $installed
        }
    }

}
else
{
    Write-Error 'Unable to test Test-WindowsFeature on this machine.'
}