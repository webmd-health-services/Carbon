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

function Set-IniEntry
{
    <#
    .SYNOPSIS
    Sets an entry in an INI file.

    .DESCRIPTION
    A configuration file consists of sections, led by a `[section]` header and followed by `name = value` entries.  This function creates or updates an entry in an INI file.  Something like this:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    Names are not allowed to contains the equal sign, `=`.  Values can contain any character.  The INI file is parsed using `Split-Ini`.  [See its documentation for more examples.](Split-Ini.html)

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Split-Ini

    LINK
    Remove-IniEntry

    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\mercurial.ini -Section extensions -Name share -Value ''

    If the `C:\Users\rspektor\mercurial.ini` file is empty, adds the following to it:

        [extensions]
        share =
    
    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\music.ini -Name genres -Value 'alternative,rock'

    If the `music.ini` file is empty, adds the following to it:

        genres = alternative,rock

    .EXAMPLE
    Set-IniEntry -Path C:\Users\rspektor\music.ini -Name genres -Value 'alternative,rock,world'

    If the `music.ini` file contains the following:

        genres = r&b

    After running this command, `music.ini` will look like this:

        genres = alternative,rock,world

    .EXAMPLE
    Set-IniEntry -Path C:\users\me\npmrc -Name prefix -Value 'C:\Users\me\npm_modules' -CaseSensitive

    Demonstrates how to set an INI entry in a case-sensitive file.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the INI file to set.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the INI entry being set.
        $Name,
        
        [string]
        # The value of the INI entry being set.
        $Value,

        [string]
        # The section of the INI where the entry should be set.
        $Section,

        [Switch]
        # Treat the INI file in a case-sensitive manner.
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'
    
    if( $Name -like '*=*' )
    {
        Write-Error "INI entry name '$Name' invalid: can not contain equal sign '='."
        return
    }
    
    
    $settings = @{ }
    $lines = New-Object 'Collections.ArrayList'
    
    if( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-Ini -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
    }
    
    $settings.Values | 
        Add-Member -MemberType NoteProperty -Name 'Updated' -Value $false -PassThru |
        Add-Member -MemberType NoteProperty -Name 'IsNew' -Value $false 
        
    $key = "$Name"
    if( $Section )
    {
        $key = "$Section.$Name"
    }
    
    if( $settings.ContainsKey( $key ) )
    {
        $setting = $settings[$key]
        if( $setting.Value -cne $Value )
        {
            Write-Verbose -Message "Updating INI entry '$key' in '$Path'."
            $lines[$setting.LineNumber - 1] = "$Name = $Value" 
        }
    }
    else
    {
        $lastItemInSection = $settings.Values | `
                                Where-Object { $_.Section -eq $Section } | `
                                Sort-Object -Property LineNumber | `
                                Select-Object -Last 1
        
        $newLine = "$Name = $Value"
        Write-Verbose -Message "Creating INI entry '$key' in '$Path'."
        if( $lastItemInSection )
        {
            $idx = $lastItemInSection.LineNumber
            $lines.Insert( $idx, $newLine )
            if( $lines.Count -gt ($idx + 1) -and $lines[$idx + 1])
            {
                $lines.Insert( $idx + 1, '' )
            }
        }
        else
        {
            if( $Section )
            {
                if( $lines.Count -gt 1 -and $lines[$lines.Count - 1] )
                {
                    [void] $lines.Add( '' )
                }
                [void] $lines.Add( "[$Section]" )
                [void] $lines.Add( $newLine )
            }
            else
            {
                $lines.Insert( 0, $newLine )
                if( $lines.Count -gt 1 -and $lines[1] )
                {
                    $lines.Insert( 1, '' )
                }
            }
        }
    }
    
    $lines | Out-File -FilePath $Path -Encoding OEM
}
