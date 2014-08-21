
filter Get-Function
{
    <#
    .SYNOPSIS
    Gets all of a module's functions.
    #>
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The file to parse for functions
        $Path
    )
    
    Write-Verbose "Loading script '$Path'."
    $scriptContent = Get-Content "$Path"
    if( -not $scriptContent )
    {
        return @()
    }

    $errors = [Management.Automation.PSParseError[]] @()
    $tokens = [System.Management.Automation.PsParser]::Tokenize( $scriptContent, [ref] $errors )
    if( $errors -ne $null -and $errors.Count -gt 0 )
    {
        Write-Error "Found $($errors.count) error(s) parsing '$Path'."
        return
    }
    
    Write-Verbose "Found $($tokens.Count) tokens in '$Path'."
    
    for( $idx = 0; $idx -lt $tokens.Count; ++$idx )
    {
        $token = $tokens[$idx]
        if( $token.Type -eq 'Keyword'-and ($token.Content -eq 'Function' -or $token.Content -eq 'Filter') )
        {
            $atFunction = $true
        }
        
        if( $atFunction -and $token.Type -eq 'CommandArgument' -and $token.Content -ne '' )
        {
            Write-Verbose "Found function '$($token.Content).'"
            $token.Content
            $atFunction = $false
        }
    }
}
