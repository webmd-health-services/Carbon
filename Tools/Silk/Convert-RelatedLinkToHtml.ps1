
function Convert-RelatedLinkToHtml
{
    <#
    .SYNOPSIS
    Converts a command's related link to HTML.

    .DESCRIPTION
    `Convert-RelatedLinkToHtml` converts a command's related link to HTML. If the related link is not a URL, the command name is converted to a link that poitns to a `CommandName.html` file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        # The related link to convert.
        $RelatedLink
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {
        if( $RelatedLink -match '^https?\:\/\/' )
        {
            '<a href="{0}">{0}</a>' -f $RelatedLink
        }
        else
        {
            '<a href="{0}.html">{0}</a>' -f $RelatedLink
        } 
    }

    end
    {
    }
}