# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Split-Ini
{
    <#
    .SYNOPSIS
    Reads an INI file and returns its contents.
    
    .DESCRIPTION
    A configuration file consists of sections, led by a "[section]" header and followed by "name = value" entries:

        [spam]
        eggs=ham
        green=
           eggs
         
        [stars]
        sneetches = belly
         
    By default, the INI file will be returned as `Carbon.Ini.IniNode` objects for each name/value pair.  For example, given the INI file above, the following will be returned:
    
        Line FullName        Section Name      Value
        ---- --------        ------- ----      -----
           2 spam.eggs       spam    eggs      ham
           3 spam.green      spam    green     eggs
           7 stars.sneetches stars   sneetches belly
    
    It is sometimes useful to get a hashtable back of the name/values.  The `AsHashtable` switch will return a hashtable where the keys are the full names of the name/value pairs.  For example, given the INI file above, the following hashtable is returned:
    
        Name            Value
        ----            -----
        spam.eggs       Carbon.Ini.IniNode;
        spam.green      Carbon.Ini.IniNode;
        stars.sneetches Carbon.Ini.IniNode;
        }

    Each line of an INI file contains one entry. If the lines that follow are indented, they are treated as continuations of that entry. Leading whitespace is removed from values. Empty lines are skipped. Lines beginning with "#" or ";" are ignored and may be used to provide comments.

    Configuration keys can be set multiple times, in which case Split-Ini will use the value that was configured last. As an example:

        [spam]
        eggs=large
        ham=serrano
        eggs=small

    This would set the configuration key named "eggs" to "small".

    It is also possible to define a section multiple times. For example:

        [foo]
        eggs=large
        ham=serrano
        eggs=small

        [bar]
        eggs=ham
        green=
           eggs

        [foo]
        ham=prosciutto
        eggs=medium
        bread=toasted

    This would set the "eggs", "ham", and "bread" configuration keys of the "foo" section to "medium", "prosciutto", and "toasted", respectively. As you can see, the only thing that matters is the last value that was set for each of the configuration keys.

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Set-IniEntry

    .LINK
    Remove-IniEntry

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini 

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    `Split-Ini` returns the following objects to the pipeline:

        Line FullName           Section    Name     Value
        ---- --------           -------    ----     -----
           2 ui.username        ui         username Regina Spektor <regina@reginaspektor.com>
           5 extensions.share   extensions share    
           6 extensions.extdiff extensions extdiff  

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini -AsHashtable

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    `Split-Ini` returns the following hashtable:

        @{
            ui.username = Carbon.Ini.IniNode (
                                FullName = 'ui.username';
                                Section = "ui";
                                Name = "username";
                                Value = "Regina Spektor <regina@reginaspektor.com>";
                                LineNumber = 2;
                            );
            extensions.share = Carbon.Ini.IniNode (
                                    FullName = 'extensions.share';
                                    Section = "extensions";
                                    Name = "share"
                                    Value = "";
                                    LineNumber = 5;
                                )
            extensions.extdiff = Carbon.Ini.IniNode (
                                       FullName = 'extensions.extdiff';
                                       Section = "extensions";
                                       Name = "extdiff";
                                       Value = "";
                                       LineNumber = 6;
                                  )
        }

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini -AsHashtable -CaseSensitive

    Demonstrates how to parse a case-sensitive INI file.

        Given this INI file:

        [ui]
        username = user@example.com
        USERNAME = user2example.com

        [UI]
        username = user3@example.com


    `Split-Ini -CaseSensitive` returns the following hashtable:

        @{
            ui.username = Carbon.Ini.IniNode (
                                FullName = 'ui.username';
                                Section = "ui";
                                Name = "username";
                                Value = "user@example.com";
                                LineNumber = 2;
                            );
            ui.USERNAME = Carbon.Ini.IniNode (
                                FullName = 'ui.USERNAME';
                                Section = "ui";
                                Name = "USERNAME";
                                Value = "user2@example.com";
                                LineNumber = 3;
                            );
            UI.username = Carbon.Ini.IniNode (
                                FullName = 'UI.username';
                                Section = "UI";
                                Name = "username";
                                Value = "user3@example.com";
                                LineNumber = 6;
                            );
        }

    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to the mercurial INI file to read.
        $Path,
        
        [Switch]
        # Pass each parsed setting down the pipeline instead of collecting them all into a hashtable.
        $AsHashtable,

        [Switch]
        # Parses the INI file in a case-sensitive manner.
        $CaseSensitive
    )

    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error ("INI file '{0}' not found." -f $Path)
        return
    }
    
    $sectionName = ''
    $lineNum = 0
    $lastSetting = $null
    $settings = @{ }
    if( $CaseSensitive )
    {
        $settings = New-Object 'Collections.Hashtable'
    }
    
    Get-Content -Path $Path | ForEach-Object {
        
        $lineNum += 1
        
        if( -not $_ -or $_ -match '^[;#]' )
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            return
        }
        
        if( $_ -match '^\[([^\]]+)\]' )
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            $sectionName = $matches[1]
            Write-Verbose "Parsed section [$sectionName]"
            return
        }
        
        if( $_ -match '^\s+(.*)$' -and $lastSetting )
        {
            $lastSetting.Value += "`n" + $matches[1]
            return
        }
        
        if( $_ -match '^([^=]*) ?= ?(.*)$' )
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            
            $name = $matches[1]
            $value = $matches[2]
            
            $name = $name.Trim()
            $value = $value.TrimStart()
            
            $setting = New-Object Carbon.Ini.IniNode $sectionName,$name,$value,$lineNum
            $settings[$setting.FullName] = $setting
            $lastSetting = $setting
            Write-Verbose "Parsed setting '$($setting.FullName)'"
        }
    }
    
    if( $AsHashtable )
    {
        return $settings
    }
    else
    {
        if( $lastSetting )
        {
            $lastSetting
        }
    }
}
