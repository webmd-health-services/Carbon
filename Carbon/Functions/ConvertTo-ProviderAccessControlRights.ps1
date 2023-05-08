
function ConvertTo-ProviderAccessControlRights
{
    <#
    .SYNOPSIS
    Converts strings into the appropriate access control rights for a PowerShell provider (e.g. FileSystemRights or
    RegistryRights).

    .DESCRIPTION
    This is an internal Carbon function, so you're not getting anything more than the synopsis.

    .EXAMPLE
    ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'

    Demonstrates how to convert `Read` and `Write` into a `System.Security.AccessControl.FileSystemRights` value.
    #>
    [CmdletBinding()]
    param(
        # The provider name.
        [Parameter(Mandatory)]
        [ValidateSet('FileSystem', 'Registry', 'CryptoKey')]
        [String] $ProviderName,

        # The values to convert.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $toFS = $ProviderName -eq 'FileSystem'
        $rightTypeName = 'Security.AccessControl.{0}Rights' -f $ProviderName

        # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
        if ($ProviderName -eq 'CryptoKey' -and -not (Test-CCryptoKeyAvailable))
        {
            $toFS = $true
            $rightTypeName = 'Security.AccessControl.FileSystemRights'
        }

        $rights = 0 -as $rightTypeName

        $foundInvalidRight = $false

        $genericToFSMap = @{
            GenericAll = 'FullControl';
            GenericExecute = 'ExecuteFile';
            GenericWrite = 'Write';
            GenericRead = 'Read';
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }

    process
    {
        Write-Debug "  ${InputObject}"
        foreach ($value in $InputObject)
        {
            if ($toFS -and $genericToFSMap.ContainsKey($value))
            {
                $value = $genericToFSMap[$value]
            }

            $right = $value -as $rightTypeName
            if (-not $right)
            {
                $allowedValues = [Enum]::GetNames($rightTypeName)
                Write-Error ("System.Security.AccessControl.{0}Rights value '{1}' not found.  Must be one of: {2}." -f $providerName,$_,($allowedValues -join ' '))
                $foundInvalidRight = $true
                return
            }
            Write-Debug "    ${value} → ${right}/0x$($right.ToString('x'))"
            $rights = $rights -bor $right
        }
    }

    end
    {
        if( $foundInvalidRight )
        {
            Write-Debug "  null"
            return $null
        }
        else
        {
            Write-Debug "  ${rights}/0x$($rights.ToString('x'))"
            $rights
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }
}
