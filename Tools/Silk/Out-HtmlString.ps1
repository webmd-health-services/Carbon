
filter Out-HtmlString
{
    <#
    .SYNOPSIS
    Writes a string out to the pipeline, trimming whitespace.
    #>
    $_ | 
        Out-String -Width 9999 | 
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
}

