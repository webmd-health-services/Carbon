function Resolve-WhiskeyNuGetPackageVersion
{
    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the NuGet package to download.
        $NuGetPackageName,

        [string]
        # The version of the package to download. Must be a three part number, i.e. it must have a MAJOR, MINOR, and BUILD number.
        $Version,

        [string]
        $NugetPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\bin\NuGet.exe' -Resolve)
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $Version )
    {
        Set-Item -Path 'env:EnableNuGetPackageRestore' -Value 'true'
        $NuGetPackage = Invoke-Command -NoNewScope -ScriptBlock {
            & $NugetPath list ('packageid:{0}' -f $NuGetPackageName)
        }
        $Version = $NuGetPackage |
            Where-Object { $_ -match $NuGetPackageName } |
            Where-Object { $_ -match ' (\d+\.\d+\.\d+.*)' } |
            ForEach-Object { $Matches[1] } |
            Select-Object -First 1

        if( -not $Version )
        {
            Write-Error ("Unable to find latest version of package '{0}'." -f $NuGetPackageName)
            return
        }
    }
    elseif( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($version) )
    {
        Write-Error "Wildcards are not allowed for NuGet packages yet because of a bug in the nuget.org search API (https://github.com/NuGet/NuGetGallery/issues/3274)."
        return
    }
    return $Version
}
