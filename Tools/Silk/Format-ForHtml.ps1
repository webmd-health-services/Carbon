
filter Format-ForHtml 
{
    <#
    .SYNOPSIS
    Encodes text for HTML.
    #>
    if( $_ )
    {
        [Web.HttpUtility]::HtmlEncode($_)
    }
}
