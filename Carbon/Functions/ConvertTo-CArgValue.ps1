
function ConvertTo-CArgValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [String] $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $InputObject)
        {
            # args.exe returns what you pass it. If it returns nothing, PowerShell isn't passing an empty string as
            # an argument, so force it to by using double-quotes.
            if (-not (& $script:argsExePath $InputObject | Measure-Object).Count)
            {
                return '""'
            }

            return $InputObject
        }

        if ($InputObject -eq (& $script:argsExePath $InputObject))
        {
            return $InputObject
        }

        return $InputObject -replace '"', '\"'
    }
}