
function ConvertTo-CBase64
{
    <#
    .SYNOPSIS
    Converts a value to base-64 encoding.

    .DESCRIPTION
    For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process.

    You're actually allowed to pass in `$null` and an empty string.  If you do, you'll get `$null` and an empty string back.

    .LINK
    ConvertFrom-CBase64

    .EXAMPLE
    ConvertTo-CBase64 -Value 'Encode me, please!'

    Encodes `Encode me, please!` into a base-64 string.

    .EXAMPLE
    ConvertTo-CBase64 -Value 'Encode me, please!' -Encoding ([Text.Encoding]::ASCII)

    Shows how to specify a custom encoding in case your string isn't in Unicode text encoding.

    .EXAMPLE
    'Encode me!' | ConvertTo-CBase64

    Converts `Encode me!` into a base-64 string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]
        # The value to base-64 encoding.
        $Value,

        [Text.Encoding]
        # The encoding to use.  Default is Unicode.
        $Encoding = ([Text.Encoding]::Unicode),

        [switch]$NoWarn
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not $NoWarn )
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -NewModuleName 'Carbon.Core'
        }
    }

    process
    {
        $Value | ForEach-Object {
            if( $_ -eq $null )
            {
                return $null
            }

            $bytes = $Encoding.GetBytes($_)
            [Convert]::ToBase64String($bytes)
        }
    }
}
