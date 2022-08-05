function Invoke-CPrivateCommand
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $Name,

        [hashtable] $Parameter = @{}
    )

    $Global:CTName = $Name
    $Global:CTParameter = $Parameter

    if( $VerbosePreference -eq 'Continue' )
    {
        $Parameter['Verbose'] = $true
    }

    $Parameter['ErrorAction'] = $ErrorActionPreference

    try
    {
        InModuleScope 'Carbon' {
            & $CTName @CTParameter
        }
    }
    finally
    {
        Remove-Variable -Name 'CTParameter' -Scope 'Global'
        Remove-Variable -Name 'CTName' -Scope 'Global'
    }
}