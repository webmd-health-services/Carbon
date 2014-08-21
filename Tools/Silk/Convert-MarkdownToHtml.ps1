
filter Convert-MarkdownToHtml
{
    if( $_ )
    {
        $markdown.Transform( $_ ).Trim()
    }
}