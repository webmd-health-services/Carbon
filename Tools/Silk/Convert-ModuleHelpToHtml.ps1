
function Convert-ModuleHelpToHtml
{
    <#
    .SYNOPSIS
    Converts a module's help into HTML.

    .DESCRIPTION
    The `Convert-ModuleHelpToHtml` function converts a module's help into HTML. It returns an object for each command and about help topic in the module. The object 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module whose help to convert.
        $ModuleName,

        [hashtable]
        # A hashtable of headings to use. They key should be the section name. The value should be the heading name. Only used when converting about help topics to HTML.
        $HeadingMap,

        [Switch]
        # Don't generate help for individual commands.
        $SkipCommandHelp
    )

    Set-StrictMode -Version 'Latest'

    $commands = Get-Command -Module $ModuleName -CommandType Cmdlet,Function,Filter 

    $aboutTopics = Get-Module -Name $ModuleName |
                        Select-Object -ExpandProperty 'ModuleBase' |
                        Get-ChildItem -Filter 'about_*.help.txt'

    $dscResources = Get-Module -Name $ModuleName |
                        Select-Object -ExpandProperty 'ModuleBase' |
                        Join-Path -ChildPath 'DscResources' |
                        Where-Object { Test-Path -Path $_ -PathType Container } |
                        Get-ChildItem -Directory 

    [int]$numCommands = $commands | Measure-Object | Select-Object -ExpandProperty 'Count'
    [int]$numAboutTopics = $aboutTopics | Measure-Object | Select-Object -ExpandProperty 'Count'
    [int]$numDscResources = $dscResources | Measure-Object | Select-Object -ExpandProperty 'Count'

    [int]$numPages = $numAboutTopics + $numDscResources
    if( -not $SkipCommandHelp )
    {
        $numPages += $numCommands
    }

    $count = 0
    foreach( $command in $commands )
    {
        if( -not $SkipCommandHelp )
        {
            Write-Progress -Activity 'Generating Module HTML' -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $command.Name
            $html = Convert-HelpToHtml -Name $command.Name
            [pscustomobject]@{
                                Name = $command.Name;
                                Type = 'Command';
                                Html = $html;
                             }
        }
    }

    <#
    foreach( $aboutTopic in $aboutTopics )
    {
        $topicName = $aboutTopic.BaseName -replace '\.help',''
        Write-Progress -Activity 'Generating Module HTML' -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $topicName
        $html = $aboutTopic | Convert-AboutTopicToHtml -ModuleName $ModuleName
        [pscustomobject]@{
                            Name = $topicName;
                            Type = 'AboutTopic';
                            Html = $html
                         }
    }
    #>

    foreach( $dscResource in $dscResources )
    {
        $dscResourceName = $dscResource.BaseName
        Write-Progress -Activity 'Generating Module HTML' -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $dscResourceName
        Import-Module -Name $dscResource.FullName
        $html = Convert-HelpToHtml -Name 'Set-TargetResource' -DisplayName $dscResourceName -Syntax (Get-DscResource -Name $dscResourceName -Syntax) -ModuleName $ModuleName
        [pscustomobject]@{
                            Name = $dscResourceName;
                            Type = 'DscResource';
                            Html = $html;
                         }
    }
}