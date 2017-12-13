
function Get-MSBuild
{
    $toolsVersionRegPath = 'hklm:\software\Microsoft\MSBuild\ToolsVersions'
    foreach( $key in (Get-ChildItem -Path $toolsVersionRegPath) )
    {
        $name = $key.Name | Split-Path -Leaf
        $toolsPath = Get-ItemProperty -Path $key.PSPath -Name 'MSBuildToolsPath' | Select -ExpandProperty 'MSBuildToolsPath'
        $msbuildPath = Join-Path -Path $toolsPath -ChildPath 'MSBuild.exe'
        if( (Test-Path -Path $msbuildPath -PathType Leaf) )
        {
            [pscustomobject]@{
                Name = $name;
                Version = [version]$name;
                Path = $msbuildPath;
            }
        }
    }

    Get-VSSetupInstance |
        ForEach-Object {
            # Prefer 64-bit binaries
            Join-Path -Path $_.InstallationPath -ChildPath 'MSBuild\*\Bin\amd64\MSBuild.exe'
            Join-Path -Path $_.InstallationPath -ChildPath 'MSBuild\*\Bin\MSBuild.exe'
        } |
        Where-Object { Test-Path -Path $_ -PathType Leaf } |
        # Prefer 64-bit binaries.
        Select-Object -First 1 |
        Resolve-Path |
        Get-Item |
        ForEach-Object {
            $name = $_.Directory.Parent.Name
            [version]$version = $null
            if( -not [version]::TryParse($name,[ref]$version) )
            {
                $name = $_.Directory.Parent.Parent.Name
            }
            [pscustomobject]@{
                                Name =  $name;
                                Version = [version]$name;
                                Path = $_.FullName
                            }
        }
}
