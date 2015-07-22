
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
        # The path to the tags file.
        $TagsJsonPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module whose index page to create.
        $ModuleName
    )

    Set-StrictMode -Version 'Latest'

    $tagsJson = Get-Content -Path $TagsJsonPath | ConvertFrom-Json
    if( -not $tagsJson )
    {
        return
    }

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

    $verbs = @{ }

    $commands = Get-Command -Module $ModuleName -CommandType Cmdlet,Function,Filter | Sort-Object -Property 'Name'
    foreach( $command in $commands )
    {
        if( -not $verbs.ContainsKey( $command.Verb ) )
        {
            $verbs[$command.Verb] = New-Object 'Collections.Generic.List[string]'
        }
        $verbs[$command.Verb].Add( $command.Name )
    }

    $commandList = $commands | Select-Object -ExpandProperty 'Name' | Sort-Object | ForEach-Object { '<li><a href="{0}.html">{0}</a></li>' -f $_ }

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

    $topicList = New-Object 'Collections.Generic.List[string]'

    $aboutTopics = Get-Module -Name $ModuleName |
                        Select-Object -ExpandProperty 'ModuleBase' |
                        Get-ChildItem -Filter 'about_*.help.txt'
    foreach( $aboutTopic in $aboutTopics )
    {
        $topicName = $aboutTopic.BaseName -replace '\.help$',''
        $virtualPath = '{0}.html' -f $topicName
        $topicList.Add( ('<li><a href="{0}">{1}</a></li>' -f $virtualPath,$topicName) )
    }

    $helpIndexArgs = @(
                        ($tagCloud -join ([Environment]::NewLine)),
                        ($commandList -join ([Environment]::NewLine)),
                        ($verbList -join ([Environment]::NewLine)),
                        ($topicList.ToArray() -join ([Environment]::NewLine))
                      )

    @'
<script src="jquery-2.1.4.min.js"></script>
<script>
jQuery( document ).ready(function() {{
    jQuery("#CommandsMenu > li").click( function() {{
        var selectedLi = jQuery("#CommandsMenu li.selected")
        selectedLi.removeClass("selected");
        
        var selectedCmdID = selectedLi.attr("id").replace("MenuItem","");
        jQuery("#" + selectedCmdID).hide();
        
        var li = jQuery(this);
        li.addClass("selected");
        
        var id = li.attr( 'id' )
        id = id.replace('MenuItem','');
        
        jQuery('#' + id).show();
        
        return false;
    }});
}});
</script>
<style>
    #CommandsMenu
    {{
        list-style: none;
        padding: 0;
        margin: 0;
    }}

    #CommandsMenu li 
    {{
        float: left;
        border-bottom-width: 0;
        margin: 0em 0.5em 0em 0.5em;
    }}

    #CommandsMenu a 
    {{
        display: block;
        padding: 0.24em 1em;
        text-align: center;
    }}

    #CommandsMenu .selected a 
    {{
        position: relative;
        top: 1px;
    }}

    #CommandsContent 
    {{
        clear: both;
        padding: 0 1em;
    }}

    #ByName, #ByVerb
    {{
        display: none;
    }}

    #ByName 
    {{
        margin-top: 1.3em;
    }}

    #ByName ul
    {{
        list-style-type: none;
    }}

    #ByName ul li
    {{
        padding: .15em 0 .15em 0;
    }}
</style>

<h2>About Help Topics</h2>

<ul>
    {3}
</ul>

<h2>Commands</h1>
<ul id="CommandsMenu">
    <li id="ByTagMenuItem" class="selected"><a href="#ByTag">By Tag</a></li>
    <li id="ByNameMenuItem" ><a href="#ByName">By Name</a></li>
    <li id="ByVerbMenuItem" ><a href="#ByVerb">By Verb</a></li>
</ul>

<div id="CommandsContent">

    <div id="ByTag">
        <a id="ByTag"></a>
        {0}
    </div>

    <div id="ByName">
        <a id="ByName"></a>
        <ul>
            {1}
        </ul>
    </div>

    <div id="ByVerb">
        <a id="ByVerb"></a>
        {2}
    </div>

</div>
'@ -f $helpIndexArgs
}