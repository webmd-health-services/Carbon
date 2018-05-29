
function Get-MSBuild
{
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Resolve-MSBuildToolsPath
    {
        param(
            [Microsoft.Win32.RegistryKey]
            $Key
        )

        $toolsPath = Get-ItemProperty -Path $Key.PSPath -Name 'MSBuildToolsPath' | Select -ExpandProperty 'MSBuildToolsPath'
        $path = Join-Path -Path $toolsPath -ChildPath 'MSBuild.exe'
        if( (Test-Path -Path $path -PathType Leaf) )
        {
            return $path
        }

        return ''
    }

    filter Test-Version
    {
        param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            $InputObject
        )

        [version]$version = $null
        [version]::TryParse($InputObject,[ref]$version)

    }

    $toolsVersionRegPath = 'hklm:\software\Microsoft\MSBuild\ToolsVersions'
    $toolsVersionRegPath32 = 'hklm:\software\Wow6432Node\Microsoft\MSBuild\ToolsVersions'
    $tools32Exists = Test-Path -Path $toolsVersionRegPath32 -PathType Container

    foreach( $key in (Get-ChildItem -Path $toolsVersionRegPath) )
    {
        $name = $key.Name | Split-Path -Leaf
        if( -not ($name | Test-Version) )
        {
            continue
        }

        $msbuildPath = Resolve-MSBuildToolsPath -Key $key
        if( -not $msbuildPath )
        {
            continue
        }

        $msbuildPath32 = $msbuildPath
        if( $tools32Exists )
        {
            $key32 = Get-ChildItem -Path $toolsVersionRegPath32 | Where-Object { ($_.Name | Split-Path -Leaf) -eq $name }
            if( $key32 )
            {
                $msbuildPath32 = Resolve-MSBuildToolsPath -Key $key32
            }
            else
            {
                $msbuildPath32 = ''
            }
        }

        [pscustomobject]@{
            Name = $name;
            Version = [version]$name;
            Path = $msbuildPath;
            Path32 = $msbuildPath32;
        }
    }

    foreach( $instance in (Get-VSSetupInstance) )
    {
        $msbuildRoot = Join-Path -Path $instance.InstallationPath -ChildPath 'MSBuild'
        if( -not (Test-Path -Path $msbuildRoot -PathType Container) )
        {
            Write-Verbose -Message ('Skipping {0} {1}: its MSBuild directory ''{2}'' doesn''t exist.' -f $instance.DisplayName,$instance.InstallationVersion,$msbuildRoot)
            continue
        }

        $versionRoots = Get-ChildItem -Path $msbuildRoot -Directory | 
                            Where-Object { Test-Version $_.Name }

        foreach( $versionRoot in $versionRoots )
        {
            $path = Join-Path -Path $versionRoot.FullName -ChildPath 'Bin\amd64\MSBuild.exe'
            $path32 = Join-Path -Path $versionRoot.FullName -ChildPath 'Bin\MSBuild.exe'
            if( -not (Test-Path -Path $path -PathType Leaf) )
            {
                $path = $path32
            }

            if( -not (Test-Path -Path $path -PathType Leaf) )
            {
                continue
            }

            if( -not (Test-Path -Path $path32 -PathType Leaf) )
            {
                $path32 = ''
            }

            [pscustomobject]@{
                                Name =  $versionRoot.Name;
                                Version = [version]$versionRoot.Name;
                                Path = $path;
                                Path32 = $path32;
                            }
        }
    }
}
