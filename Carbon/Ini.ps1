
function Set-IniEntry
{
    <#
    .SYNOPSIS
    Sets an entry in an INI file.
    .DESCRIPTION
    
    A configuration file consists of sections, led by a "[section]" header
    and followed by "name = value" entries.  This function creates or updates
    an entry in an INI file.
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
        $Section
    )
    
    if( $Name -like '*=*' )
    {
        Write-Error "INI entry name '$Name' invalid: can not contain equal sign '='."
        return
    }
    
    
    $settings = @{ }
    $lines = New-Object 'Collections.ArrayList'
    
    if( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-Ini -Path $Path
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
    }
    
    $settings.Values | ForEach-Object { $_.Updated = $false ; $_.IsNew = $false }
    
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
            Write-Host "Updating INI entry '$key' in '$Path'."
            $lines[$setting.LineNumber] = "$Name = $Value" 
        }
    }
    else
    {
        $lastItemInSection = $settings.Values | Where-Object { $_.Section -eq $Section } | Sort-Object -Property LineNumber | Select-Object -Last 1
        
        $newLine = "$Name = $Value"
        Write-Host "Creating INI entry '$key' in '$Path'."
        if( $lastItemInSection )
        {
            $idx = $lastItemInSection.LineNumber + 1
            $lines.Insert( $idx, $newLine )
            if( $lines[$idx + 1] )
            {
                $lines.Insert( $idx + 1, '' )
            }
        }
        else
        {
            if( $Section )
            {
                if( $lines[$lines.Count - 1] )
                {
                    [void] $lines.Add( '' )
                }
                [void] $lines.Add( "[$Section]" )
                [void] $lines.Add( $newLine )
            }
            else
            {
                $lines.Insert( 0, $newLine )
                if( $lines[1] )
                {
                    $lines.Insert( 1, '' )
                }
            }
        }
    }
    
    $lines | Out-File -FilePath $Path -Encoding OEM
}

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