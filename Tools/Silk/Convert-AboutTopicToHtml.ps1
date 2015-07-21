4
function Convert-AboutTopicToHtml
{
    <#
    .SYNOPSIS
    Converts an about topic into HTML.

    .DESCRIPTION
    The `Convert-AboutTopicToHtml` converts a PowerShell about topic into HTML. The about topic is expected to be [formatted like PowerShell's internal topics](https://msdn.microsoft.com/en-us/library/Dd878343.aspx):

        TOPIC
            about_<subject or module name>
        
        SHORT DESCRIPTION
            A short, one-line description of the topic contents.
        
        LONG DESCRIPTION
            A detailed, full description of the subject or purpose of the module.
        
        EXAMPLES
            Examples of how to use the module or how the subject feature works in practice.
        
        KEYWORDS
            Terms or titles on which you might expect your users to search for the information in this topic.
        
        SEE ALSO
            Text-only references for further reading. Hyperlinks cannot work in the Windows PowerShell console. 
    
    `Convert-AboutTopicToHtml` does the following:
    
     * Removes the `TOPIC` AND `SHORT DESCRIPTION` headers
     * Wraps the topic name in an <h1> tag
     * Renames the `LONG DESCRIPTION` heading to '<h2>Description</h2>
     * Wraps all other headers in <h2> elements.
     * Converts the bodies of each section to HTML 

    Lines that don't begin with spaces are assumed to be headers.

    Lines that begin with spaces are assumed to be content written in Markdown.

    The `SEE ALSO` section is parsed, one line at a time for links, command names, and other help topics, e.g.

        SEE ALSO
            https://msdn.microsoft.com/en-us/library/Dd878343.aspx
            about_Silk
            Convert-AboutTopicToHtml

    Would convert into a three item list, the first a link to the web, the second a link to the `about_Silk.html` topic, and the third to the `Convert-AboutTopicToHtml.html` page.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The name of the help topic, include the `about_` prefix, or a `FileInfo` object representing the help topic.
        $InputObject,

        [string]
        # The name of the module being documented.
        $ModuleName,

        [string]
        # The heading used for the topic's name. Default is `TOPIC`.
        $TopicHeading = 'TOPIC',

        [string]
        # The heading used for the topic's short description. Default is `SHORT DESCRIPTION`.
        $ShortDescriptionHeading = 'SHORT DESCRIPTION',

        [string]
        # The heading used for the topic's long description. Default is `LONG DESCRIPTION`.
        $LongDescriptionHeading = 'LONG DESCRIPTION',

        [string]
        # The heading used for the topic's `See Also` section. Default is `SEE ALSO`.
        $SeeAlsoHeading = 'SEE ALSO'
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        function Complete-Section
        {
            param(
                [string]
                $Heading,

                [Parameter(Mandatory=$true)]
                [AllowEmptyString()]
                [string]
                $Body
            )

            $Body = $Body.Trim()
            switch( $Heading )
            {
                $TopicHeading
                {
                    # We just don't want to do any Markdown conversion.
                }

                $SeeAlsoHeading
                {
                    $lines = $Body -split ([Environment]::NewLine) | 
                                Convert-RelatedLinkToHtml -ModuleName $ModuleName | 
                                ForEach-Object { '<li>{0}</li>' -f $_ }
                    $Body = @'
    <ul>
        {0}
    </ul>
'@ -f ($lines -join [Environment]::NewLine)
                }
                default
                {
                    $Body = $Body | Convert-MarkdownToHtml 
                }
            }

            $topic | Add-Member -Name $Heading -MemberType NoteProperty -Value $Body
        }

        if( $InputObject -is [IO.FileInfo] )
        {
            [string[]]$lines = $InputObject | Get-Content
            $topicName = $InputObject.BaseName -replace '\.help$' -f ''
        }
        else
        {
            [string[]]$lines = Get-Help -Name $InputObject
            if( -not $lines )
            {
                Write-Error ('About topic ''{0}'' not found.' -f $InputObject)
                return
            }
            $topicName = $InputObject
        }

        $topic = [pscustomobject]@{ }
        $currentHeader = $null
        $currentContent = $null
        $sectionOrder = New-Object 'Collections.Generic.List[string]'
        $lastLineIdx = $lines.Count - 1
        for( $idx = 0; $idx -lt $lines.Count; ++$idx )
        {
            $line = $lines[$idx]

            if( $line -match '^\s+' )
            {
                $currentContent.AppendLine( $line.Trim() )
                if( $idx -eq $lastLineIdx )
                {
                    Complete-Section -Heading $currentHeader -Body $currentContent.ToString()
                }

                continue

            }
            else
            {
                # Header
                if( $currentHeader )
                {
                    Complete-Section -Heading $currentHeader -Body $currentContent.ToString()
                }

                $currentContent = New-Object 'Text.StringBuilder'
                $currentHeader = $line
                $sectionOrder.Add( $currentHeader )
            }
        }

        if( -not ($topic | Get-Member -Name $TopicHeading) )
        {
            Write-Warning ('Topic ''{0}'' doesn''t have a ''{1}'' heading. Defaulting to {0}. Use the `TopicHeading` parameter to set the topic''s topic heading.' -f $topicName,$TopicHeading)
            Complete-Section -Heading 'TOPIC' -Body $topicName
        }

        if( -not ($topic | Get-Member -Name $ShortDescriptionHeading) )
        {
            Write-Warning ('Topic ''{0}'' doesn''t have a ''{1}'' heading. Use the `ShortDescription` parameter to set the topic''s SHORT DESCRIPTION heading.' -f $topicName,$ShortDescriptionHeading)
            Complete-Section -Heading 'SHORT DESCRIPTION' -Body ''
        }

        if( -not ($topic | Get-Member -Name $LongDescriptionHeading) )
        {
            Write-Warning ('Topic ''{0}'' doesn''t have a ''{1}'' heading. Use the `lONGDescription` parameter to set the topic''s LONG DESCRIPTION heading.' -f $topicName,$LongDescriptionHeading)
            Complete-Section -Heading 'LONG DESCRIPTION' -Body ''
        }

        $content = New-Object 'Text.StringBuilder'
        foreach( $section in $sectionOrder )
        {
            if( $section -eq $TopicHeading -or $section -eq $ShortDescriptionHeading -or $section -eq $LongDescriptionHeading )
            {
                continue
            }

            $content.AppendLine( ('<h2>{0}</h2>' -f $section) )
            $content.AppendLine( $topic.$Section )
        }

        @'
    <h1>{0}</h1>

    {1}

    <h2>Description</h2>

    {2}

    {3}

'@ -f $topic.$TopicHeading,$topic.$ShortDescriptionHeading,$topic.$LongDescriptionHeading,$content

    }

    end
    {
    }
}