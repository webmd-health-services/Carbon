
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

        [string[]]
        # Any scripts included in the module whose help should get generated. Scripts are assumed to be in the root of the module.
        $Script,

        [hashtable]
        # A hashtable of headings to use. They key should be the section name. The value should be the heading name. Only used when converting about help topics to HTML.
        $HeadingMap,

        [Switch]
        # Don't generate help for individual commands.
        $SkipCommandHelp
    )

    Set-StrictMode -Version 'Latest'

    $commands = Get-Command -Module $ModuleName -CommandType Cmdlet,Function,Filter 

    $moduleBase = Get-Module -Name $ModuleName |
                        Select-Object -ExpandProperty 'ModuleBase'


    $aboutTopics = @()
    if( (Test-Path -Path (Join-Path -Path $moduleBase -ChildPath 'en-US') -PathType Container) )
    {
        $aboutTopics = Get-ChildItem -Path $moduleBase -Filter 'en-US\about_*.help.txt'
    }

    $dscResources = Join-Path -Path $moduleBase -ChildPath 'DscResources' |
                        Where-Object { Test-Path -Path $_ -PathType Container } |
                        Get-ChildItem -Directory 

    $scripts = @()
    if( $Script ) 
    {
        $scripts = $Script | 
                        ForEach-Object { Join-Path -Path $moduleBase -ChildPath $_ } |
                        Get-Item
    }

    [int]$numCommands = $commands | Measure-Object | Select-Object -ExpandProperty 'Count'
    [int]$numScripts = $scripts | Measure-Object | Select-Object -ExpandProperty 'Count'
    [int]$numAboutTopics = $aboutTopics | Measure-Object | Select-Object -ExpandProperty 'Count'
    [int]$numDscResources = $dscResources | Measure-Object | Select-Object -ExpandProperty 'Count'

    [int]$numPages = $numAboutTopics + $numDscResources + $numScripts
    if( -not $SkipCommandHelp )
    {
        $numPages += $numCommands
    }

    $activity = 'Generating {0} Module HTML' -f $ModuleName
    $count = 0
    foreach( $command in $commands )
    {
        if( -not $SkipCommandHelp )
        {
            Write-Progress -Activity $activity -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $command.Name -Status 'Commands'
            $html = Convert-HelpToHtml -Name $command.Name -Script $Script -ModuleName $ModuleName
            [pscustomobject]@{
                                Name = $command.Name;
                                Type = 'Command';
                                Html = $html;
                             }
        }
    }

    foreach( $scriptItem in $scripts )
    {
        Write-Progress -Activity $activity -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $command.Name -Status 'Scripts'
        $html = Convert-HelpToHtml -Name $scriptItem.FullName -ModuleName $ModuleName -Script $Script
        [pscustomobject]@{
                            Name = $scriptItem.Name;
                            Type = 'Script'
                            Html = $html;
                         }
    }

    foreach( $aboutTopic in $aboutTopics )
    {
        $topicName = $aboutTopic.BaseName -replace '\.help',''
        Write-Progress -Activity $activity -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $topicName -Status 'About Topics'
        $html = $aboutTopic | Convert-AboutTopicToHtml -ModuleName $ModuleName -Script $Script
        [pscustomobject]@{
                            Name = $topicName;
                            Type = 'AboutTopic';
                            Html = $html
                         }
    }

    foreach( $dscResource in $dscResources )
    {
        $dscResourceName = $dscResource.BaseName
        Write-Progress -Activity $activity -PercentComplete ($count++ / $numPages * 100) -CurrentOperation $dscResourceName -Status 'DSC Resources'
        Import-Module -Name $dscResource.FullName
        $html = Convert-HelpToHtml -Name 'Set-TargetResource' -DisplayName $dscResourceName -Syntax (Get-DscResource -Name $dscResourceName -Syntax) -ModuleName $ModuleName -Script $Script
        [pscustomobject]@{
                            Name = $dscResourceName;
                            Type = 'DscResource';
                            Html = $html;
                         }
    }
}