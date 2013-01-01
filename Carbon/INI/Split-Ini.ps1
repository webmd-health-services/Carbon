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
    Reads an ini file and returns its contents as a hashtable.
    
    .DESCRIPTION
    A configuration file consists of sections, led by a "[section]" header
    and followed by "name = value" entries:

        [spam]
        eggs=ham
        green=
           eggs
         
        [stars]
        sneetches = belly
         
    This file will be returned as a hash like this:
    
        @{
            spam.eggs =  @{
                            Section = 'spam';
                            Name = 'eggs';
                            Value = 'ham';
                            LineNumber = 1;
                          };
            spam.green = @{
                            Section = 'spam';
                            Name = 'green';
                            Value = "`neggs";
                            LineNumber = 2;
                          };
            stars.sneetches = @{
                                    Section = 'stars';
                                    Name = 'sneetches';
                                    Value = 'belly'
                                    LineNumber = 6;
                               }
        }

    Each line contains one entry. If the lines that follow are indented, they
    are treated as continuations of that entry. Leading whitespace is removed
    from values. Empty lines are skipped. Lines beginning with "#" or ";" are
    ignored and may be used to provide comments.

    Configuration keys can be set multiple times, in which case Split-Ini
    will use the value that was configured last. As an example:

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

    This would set the "eggs", "ham", and "bread" configuration keys of the
    "foo" section to "medium", "prosciutto", and "toasted", respectively. As
    you can see there only thing that matters is the last value that was set
    for each of the configuration keys.

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini 

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    `Split-Ini` returns the following hashtable:

        @{
            ui.username = @{
                                FullName = 'ui.username';
                                Section = "ui";
                                Name = "username";
                                Value = "Regina Spektor <regina@reginaspektor.com>";
                                LineNumber = 1;
                            };
            extensions.share = @{
                                    FullName = 'extensions.share';
                                    Section = "extensions";
                                    Name = "share"
                                    Value = "";
                                    LineNumber = 4;
                                };
            extensions.extdiff = @{
                                       FullName = 'extensions.extdiff';
                                       Section = "extensions";
                                       Name = "extdiff";
                                       Value = "";
                                       LineNumber = 5;
                                  };
        }

    .EXAMPLE
    Split-Ini -Path C:\Users\rspektor\mercurial.ini -PassThru

    Given this INI file:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    `Split-Ini` returns the following hashtables to the pipeline:

        @{
            FullName = 'ui.username';
            Section = "ui";
            Name = "username";
            Value = "Regina Spektor <regina@reginaspektor.com>";
            LineNumber = 1;
        }
        @{
            FullName = 'extensions.share';
            Section = "extensions";
            Name = "share"
            Value = "";
            LineNumber = 4;
        }
        @{
           FullName = 'extensions.extdiff';
           Section = "extensions";
           Name = "extdiff";
           Value = "";
           LineNumber = 5;
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
        $PassThru
    )

    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error "Unable to find INI file at '$Path'."
        return $null
    }
    
    $sectionName = ''
    $lineNum = -1
    $lastSetting = $null
    $settings = @{ }
    
    Get-Content -Path $Path | ForEach-Object {
        
        $lineNum += 1
        
        if( -not $_ -or $_ -match '^[;#]' )
        {
            if( $PassThru -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            return
        }
        
        if( $_ -match '^\[([^\]]+)\]' )
        {
            if( $PassThru -and $lastSetting )
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
            if( $PassThru -and $lastSetting )
            {
                $lastSetting
            }
            
            $name = $matches[1]
            $value = $matches[2]
            
            $name = $name.Trim()
            $value = $value.TrimStart()
            
            $fullName = "$name"
            if( $sectionName )
            {
                $fullName = "$sectionName.$name"
            }
            $setting =  @{
                            Section = $sectionName;
                            Name = $name;
                            FullName = $fullName
                            Value = $value;
                            LineNumber = $lineNum;
                         }
            $settings[$setting.FullName] = $setting
            $lastSetting = $setting
            Write-Verbose "Parsed setting '$($setting.FullName)'"
        }
    }
    
    if( $PassThru )
    {
        if( $lastSetting )
        {
            $lastSetting
        }
    }
    else
    {
        return $settings
    }
}
