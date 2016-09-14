
function New-ModuleHelpIndex
{
    <#
    .SYNOPSIS
    Creates an index page for a module's help.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module whose index page to create.
        $ModuleName,

        [string[]]
        # The names of any scripts that should be included.
        $Script,

        [string]
        # The path to the tags file. If not provided, no tag tab is generated.
        $TagsJsonPath
    )

    Set-StrictMode -Version 'Latest'

    if( $TagsJsonPath )
    {
        $tagsJson = Get-Content -Path $TagsJsonPath | ConvertFrom-Json

        $tags = @{ }

        foreach( $item in $tagsJson )
        {
            foreach( $tagName in $item.Tags )
            {
                if( -not $tags.ContainsKey( $tagName ) )
                {
                    $tags[$tagName] = New-Object 'Collections.Generic.List[string]'
                }

                $tags[$tagName].Add( $item.Name )
            }
        }

        $tagCloud = $tags.Keys | Sort-Object | ForEach-Object { 

        $commands = $tags[$_] | ForEach-Object { '<li><a href="{0}.html">{0}</a></li>' -f $_ }
        @'
    <h3>{0}</h3>

    <ul>
        {1}
    </ul>
'@ -f $_,($commands -join ([Environment]::NewLine))
        }

    }
    else
    {
        $tagCloud = ''
    }

    $verbs = @{ }

    $commands = Get-Command -Module $ModuleName -CommandType Cmdlet,Function,Filter 
    foreach( $command in $commands )
    {
        if( -not $verbs.ContainsKey( $command.Verb ) )
        {
            $verbs[$command.Verb] = New-Object 'Collections.Generic.List[string]'
        }
        $verbs[$command.Verb].Add( $command.Name )
    }

    $commandList = Invoke-Command {
                                        $commands |  Select-Object -ExpandProperty 'Name'
                                        $moduleBase = Get-Module -Name $ModuleName | Select-Object -ExpandProperty 'ModuleBase'
                                        $dscResourceBase = Join-Path -Path $moduleBase -ChildPath 'DscResources'
                                        if( (Test-Path -Path $dscResourceBase -PathType Container) )
                                        {
                                            Get-ChildItem -Directory -Path $dscResourceBase
                                        }
                                    } |
                        Sort-Object | 
                        ForEach-Object { '<li><a href="{0}.html">{0}</a></li>' -f $_ }
    $commandList = @'
<ul>
    {0}
</ul>
'@ -f ($commandList -join ([Environment]::NewLine))

    $verbList = $verbs.Keys | Sort-Object | ForEach-Object {
        $verb = $_
        $verbCommands = $verbs[$verb] | ForEach-Object { '<li><a href="{0}.html">{0}</a></li>' -f $_ }
        @'
    <h3>{0}</h3>

    <ul>
        {1}
    </ul>
'@ -f $verb,($verbCommands -join ([Environment]::NewLine))
    }

    $scriptContent = ''
    if( $Script )
    {
        $scriptContent = @"
<h2>Scripts</h2>

<ul>
    $($Script | ForEach-Object { '<li><a href="{0}.html">{0}</a></li>' -f $_ })
</ul>
"@
    }

    $topicList = New-Object 'Collections.Generic.List[string]'

    $moduleBase = Get-Module -Name $ModuleName |  Select-Object -ExpandProperty 'ModuleBase'
    $aboutTopics = @()
    if( (Test-Path -Path (Join-Path -Path $moduleBase -ChildPath 'en-US') -PathType Container) )
    {
        $aboutTopics = Get-ChildItem -Path $moduleBase -Filter 'en-US\about_*.help.txt'
    }

    foreach( $aboutTopic in $aboutTopics )
    {
        $topicName = $aboutTopic.BaseName -replace '\.help$',''
        $virtualPath = '{0}.html' -f $topicName
        $topicList.Add( ('<li><a href="{0}">{1}</a></li>' -f $virtualPath,$topicName) )
    }

    function New-CommandsMenuItem
    {
        param(
            $ID,
            $Name
        )

        Set-StrictMode -Version 'Latest'

        if( -not $tagCloud -and $ID -eq 'ByTag' )
        {
            return
        }

        $selectedAttr = ''
        if( ($tagCloud -and $ID -eq 'ByTag') -or ($ID -eq 'ByName' -and -not $tagCloud) )
        {
            $selectedAttr = 'class="selected"'
        }

        '<li id="{0}MenuItem" {1}><a href="#{0}">{2}</a></li>' -f $ID,$selectedAttr,$Name
    }

    function New-CommandContentDiv
    {
        param(
            $ID,
            $Line
        )

        Set-StrictMode -Version 'Latest'

        if( -not $Line )
        {
            return
        }

        $styleAttr = 'display:none;'
        if( ($ID -eq 'Tag' -and $tagCloud) -or ($ID -eq 'Name' -and -not $tagCloud) )
        {
            $styleAttr = ''
        }

        @'
<div id="By{0}Content" style="{2}">
    <a id="By{0}"></a>

    {1}

</div>
'@ -f $ID,($Line -join ([Environment]::NewLine)),$styleAttr
    }

    @"
<script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
<script>
jQuery( document ).ready(function() {
    jQuery("#CommandsMenu > li").click( function() {
        var selectedLi = jQuery("#CommandsMenu li.selected")
        selectedLi.removeClass("selected");
        
        var selectedCmdID = selectedLi.attr("id").replace("MenuItem","");
        jQuery("#" + selectedCmdID + 'Content').hide();
        
        var li = jQuery(this);
        li.addClass("selected");
        
        var id = li.attr( 'id' )
        id = id.replace('MenuItem','');
        
        jQuery('#' + id + 'Content').show();
        
        return false;
    });
});
</script>

<h2>About Help Topics</h2>

<ul>
    $($topicList.ToArray() -join ([Environment]::NewLine))
</ul>

$($scriptContent)

<h2>Commands</h1>

<ul id="CommandsMenu">
    $( New-CommandsMenuItem 'ByTag' 'By Tag' )
    $( New-CommandsMenuItem 'ByName' 'By Name' )
    $( New-CommandsMenuItem 'ByVerb' 'By Verb' )
</ul>

<div id="CommandsContent">

    $( New-CommandContentDiv 'Tag' $tagCloud )
    $( New-CommandContentDiv 'Name' $commandList )
    $( New-CommandContentDiv 'Verb' $verbList )

</div>
"@

}