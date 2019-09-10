
function Format-CADSearchFilterValue
{
    <#
    .SYNOPSIS
    Escapes Active Directory special characters from a string.
    
    .DESCRIPTION
    There are special characters in Active Directory queries/searches.  This function escapes them so they aren't treated as AD commands/characters.
    
    .OUTPUTS
    System.String.  The input string with any Active Directory-sensitive characters escaped.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters

    .EXAMPLE
    Format-CADSearchFilterValue -String "I have AD special characters (I think)."

    Returns 

        I have AD special characters \28I think\29.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The string to escape.
        $String
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $string = $string.Replace('\', '\5c')
    $string = $string.Replace('*', '\2a')
    $string = $string.Replace('(', '\28')
    $string = $string.Replace(')', '\29')
    $string = $string.Replace('/', '\2f')
    $string.Replace("`0", '\00')
}

Set-Alias -Name 'Format-ADSpecialCharacters' -Value 'Format-CADSearchFilterValue'

