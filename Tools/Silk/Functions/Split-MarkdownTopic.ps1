
function Split-MarkdownTopic
{
    <#
    .SYNOPSIS
    Parses a Markdown-formatted module help topic, e.g. about_Module.

    .DESCRIPTION
    A Markdown-formatted help topic should contain four sections, `Topic`, `Short Description`, `Long Description`, and `See Also`.  These should all be formatted as level-1 headings.  For example:

        # Topic

        about_Silk

        # Short Description

        Silk is a PowerShell module used to convert another module's help system into an HTML website.

        # Long Description

        MOre details here.  Yadda, yadda, yadda.

        # See Also

        about_Silk_AdditionalTopic
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        # The root where the config file was found.
        $ConfigFileRoot,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # An object containing information about the topic to parse.
        $TopicInfo
    )
    process
    {
        Set-StrictMode -Version Latest

        $path = $TopicInfo.Path
        if( -not (Test-Path -Path $path -PathType Leaf) )
        {
            Write-Error ('Markdown help topic <{0}> not found.' -f $path)
            return
        }

        $content = New-Object Collections.ArrayList
        $sectionName = $null
        $eof = [Guid]::NewGuid().ToString()
        $topic = New-Object PsObject -Property @{ Name = ''; Synopsis = ''; Description = ''; RelatedLinks = ''; FileName = $TopicInfo.FileName }
        $lineNum = 0
        Invoke-Command { Get-Content -Path $path ; $eof } | ForEach-Object {
            if( $_ -match '^# (.*)$' -or $_ -eq $eof )
            {
                if( $sectionName -or $_ -eq $eof )
                {
                    $topic.$sectionName = $content -join "`n"
                    $topic.$sectionName = $topic.$sectionName.Trim()
                    if( $_ -eq $eof )
                    {
                        return
                    }
                    $content.Clear()
                }


                $sectionName = $matches[1]
                switch -Regex ($sectionName)
                {
                    'Topic|Name' 
                    {
                        $sectionName = 'Name'
                    }
                    'Short Description|Synopsis'
                    {
                        $sectionName = 'Synopsis'
                    }
                    'Long Description|Description'
                    {
                        $sectionName = 'Description'
                    }
                    'See Also|(Related )?Links?'
                    {
                        $sectionName = 'RelatedLinks'
                    }
                    default
                    {
                        Write-Error ('{0}: line {1}: Unknown top-level heading <{2}>.  Expected <Name>, <Synopsis>, <Description>, or <Link>. <Link> may be used multiple times.' -f $path,$lineNum,$_)
                    }
                }
            }
            else
            {
                if( -not $sectionName )
                {
                    Write-Error ('{0}: line {1}: Invalid Markdown help topic: the first line must be `# Name`.' -f $path,$lineNum)
                    return
                }
                [void] $content.Add( $_ )
            }
            ++$lineNum
        }

        if( $TopicInfo | Get-Member Title )
        {
            $topic.Name = $TopicInfo.Title
        }
        return $topic
    }
}