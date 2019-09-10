
function Assert-WindowsFeatureFunctionsSupported
{
    <#
    .SYNOPSIS
    INTERNAL.  DO NOT USE.  
    
    .DESCRIPTION 
    INTERNAL.  DO NOT USE.
    
    .EXAMPLE
    Assert-WindowsFeatureFunctionsSupported
    
    Writes an error and returns `false` if support for managing functions isn't found.
    #>
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $null -eq $windowsFeaturesNotSupported )
    {
        $script:useServerManager = $null -ne (Get-Command -Name 'servermanagercmd.exe' -ErrorAction Ignore)
        $useWmi = $false
        if( -not $useServerManager )
        {
            $win32OptionalFeatureClass = $null
            if( (Get-Command -Name 'Get-CimClass' -ErrorAction Ignore) )
            {
                $win32OptionalFeatureClass = Get-CimClass -ClassName 'Win32_OptionalFeature'
            }
            elseif( Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore )
            {
                $win32OptionalFeatureClass = Get-WmiObject -List | Where-Object { $_.Name -eq 'Win32_OptionalFeature' }
            }
                
            $useWmi = $null -ne $win32OptionalFeatureClass
            $script:useOCSetup = $null -ne (Get-Command -Name 'ocsetup.exe' -ErrorAction Ignore )
        }

        $script:windowsFeaturesNotSupported = (-not ($useServerManager -or ($useWmi -and $useOCSetup) ))
    }

    if( $windowsFeaturesNotSupported )
    {
        Write-Warning $supportNotFoundErrorMessage
        return $false
    }
    return $true
}

