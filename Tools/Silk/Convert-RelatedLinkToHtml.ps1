
function Convert-RelatedLinkToHtml
{
    <#
    .SYNOPSIS
    Converts a command's related link to HTML.

    .DESCRIPTION
    `Convert-RelatedLinkToHtml` converts a command's related links to HTML. If the related link is not a URL, the command name is converted to a link that poitns to a `CommandName.html` file.


    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The help object returned by `Get-Help`.
        $CommandHelp,

        [string]
        # The name of the module the command is in.
        $ModuleName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

    }

    process
    {
        if( ($CommandHelp | Get-Member -Name 'ModuleName') -and $CommandHelp.ModuleName )
        {
            $ModuleName = $CommandHelp.ModuleName
        }

        $aboutTopics = @()
        if( $ModuleName )
        {
            $aboutTopics = Get-Module -Name $ModuleName | 
                                Select-Object -ExpandProperty 'ModuleBase' | 
                                Get-ChildItem -Filter 'about_*' | 
                                Select-Object -ExpandProperty 'BaseName' | 
                                ForEach-Object { $_ -replace '\.help$','' }
        }

        Invoke-Command -ScriptBlock {
                if( $CommandHelp | Get-Member -Name 'RelatedLinks' )
                {
                     return $CommandHelp.RelatedLinks |
                                Out-String -Width ([Int32]::MaxValue) |
                                ForEach-Object { $_ -split "`n" } |
                                ForEach-Object { $_.Trim() } |
                                Where-Object { $_ }
                }

                if( $CommandHelp -is [string] )
                {
                    return $CommandHelp
                }
            } |
            ForEach-Object {
                if( $_ -match '^https?\:\/\/' )
                {
                    return '<a href="{0}">{0}</a>' -f $_
                }

                if( $ModuleName -and (Get-Command -Name $_ -Module $ModuleName -ErrorAction Ignore) )
                {
                    return '<a href="{0}.html">{0}</a>' -f $_
                }

                $cmd = Get-Command -Name $_ -ErrorAction Ignore
                if( $cmd -and $cmd.HelpUri )
                {
                    return '<a href="{0}.html">{1}</a>' -f $cmd.HelpUri,$_
                }

                if( $aboutTopics -contains $_ )
                {
                    return '<a href="{0}.html">{0}</a>' -f $_
                }
                
                return $_
            }
    }

    end
    {
    }
}