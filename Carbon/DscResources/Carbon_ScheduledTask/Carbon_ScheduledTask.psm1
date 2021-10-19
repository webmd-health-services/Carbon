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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [string]
        # Install the task from this XML.
        $TaskXml,

        [Management.Automation.PSCredential]
        # The principal the task should run as. Use `Principal` parameter to run as a built-in security principal. Required if `Interactive` or `NoPassword` switches are used.
        $TaskCredential,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $canonicalName = $Name
    if( -not $canonicalName.StartsWith('\') )
    {
        $canonicalName = '\{0}' -f $canonicalName
    }

    $resource = @{
                    Name = $Name;
                    TaskXml = '';
                    TaskCredential = $null;
                    Ensure = 'Absent';
                }

    if( (Test-CScheduledTask -Name $canonicalName) )
    {
        $task = Get-CScheduledTask -Name $canonicalName -AsComObject
        $principal = $task.Definition.Principal
        $principalName = $principal.UserId
        if( -not $principalName )
        {
            $principalName = $principal.GroupId
        }

        $resource.TaskCredential = $principalname
        $resource.TaskXml = $task.Xml
        $resource.Ensure = 'Present'
    }

    return $resource
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for configuring scheduled tasks.

    .DESCRIPTION
    The `Carbon_ScheduledTask` resource configures scheduled tasks using `schtasks.exe` with [Task Scheduler XML](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx).

    The task is installed when the `Ensure` property is set to `Present`. If the task already exists, and the XML of the current task doesn't match the XML passed in, the task is deleted, and a new task is created in its place. The XML comparison is pretty dumb: it compares the XML document(s) as a giant string, not element by element. This means if your XML doesn't order elements in the same way as `schtasks.exe /query /xml`, then your task will always be deleted and re-created. This may or may not be a problem for you.

    `Carbon_ScheduledTask` is new in Carbon 2.0.

    .LINK
    Get-CScheduledTask

    .LINK
    Install-CScheduledTask

    .LINK
    Test-CScheduledTask

    .LINK
    Uninstall-CScheduledTask

    .LINK
    http://technet.microsoft.com/en-us/library/cc725744.aspx#BKMK_create
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx

    .EXAMPLE
    >
    Demonstrates how to install a new or update an existing scheduled task that runs as a built-in user. The user's SID should be declared in the task XML file.

        Carbon_ScheduledTask InstallScheduledTask
        {
            Name = 'ClearApplicationCache';
            TaskXml = (Get-Content -Path $clearApplicationCacheTaskPath.xml -Raw);
        }

    .EXAMPLE
    >
    Demonstrates how to install a new or update an existing scheduled task that runs as a custom user. 

        Carbon_ScheduledTask InstallScheduledTask
        {
            Name = 'ClearApplicationCache';
            TaskXml = (Get-Content -Path $clearApplicationCacheTaskPath.xml -Raw);
            TaskCredential = (Get-Credential 'runasuser');
        }

    .EXAMPLE
    >
    Demonstrates how to remove a scheduled task.

        Carbon_ScheduledTask InstallScheduledTask
        {
            Name = 'ClearApplicationCache';
            Ensure = 'Absent';
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [string]
        # Install the task from this XML.
        $TaskXml,

        [Management.Automation.PSCredential]
        # The identity that should run the task. The default is `SYSTEM`.
        $TaskCredential,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $PSBoundParameters.Remove('Ensure')

    if( $Ensure -eq 'Present' )
    {
        $installParams = @{ }
        if( (Test-CScheduledTask -Name $Name ) )
        {
            Write-Verbose ('[{0}] Re-installing' -f $Name)
            $installParams['Force'] = $true
        }
        else
        {
            Write-Verbose ('[{0}] Installing' -f $Name)
        }
        Install-CScheduledTask @PSBoundParameters @installParams
    }
    else
    {
        Write-Verbose ('[{0}] Uninstalling' -f $Name)
        Uninstall-CScheduledTask -Name $Name
    }

}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [string]
        # Install the task from this XML.
        $TaskXml,

        [Management.Automation.PSCredential]
        # The principal the task should run as. Use `Principal` parameter to run as a built-in security principal. Required if `Interactive` or `NoPassword` switches are used.
        $TaskCredential,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the task is installed/updated. If `Absent`, the task is removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name

    if( $Ensure -eq 'Present' )
    {
        if( $resource.Ensure -eq 'Absent' )
        {
            Write-Verbose ('[{0}] Desired scheduled task not found' -f $Name)
            return $false
        }

        if( -not $TaskXml )
        {
            Write-Error ('Property ''TaskXml'' is missing or empty. When creating a scheduled task, the ''TaskXml'' property is required.')
            return $true
        }

        $resourceXml = [xml]$resource.TaskXml
        $currentTaskXml = $resourceXml.OuterXml
        $desiredTaskXml = ([xml]$TaskXml).OuterXml
        if( $currentTaskXml -ne $desiredTaskXml )
        {
            $differsAt = 0
            for( $idx = 0; $idx -lt $desiredTaskXml.Length -and $idx -lt $currentTaskXml.Length; ++$idx )
            {
                $charEqual = $desiredTaskXml[$idx] -eq $currentTaskXml[$idx]

                if( -not $charEqual )
                {
                    $differsAt = $idx
                    break
                }
            }
  
            $nameLength = $Name.Length
            $linePrefix = ' ' * ($nameLength + 2)
            $msgFormat = @'
'@        
            Write-Verbose ('[{0}] Task XML differs:' -f $Name)
            $startIdx = $differsAt - 35
            if( $startIdx -lt 0 )
            {
                $startIdx = 0
            }

            $shortestLength = $currentTaskXml.Length
            if( $desiredTaskXml.Length -lt $shortestLength )
            {
                $shortestLength = $desiredTaskXml.Length
            }

            $length = 70
            if( $startIdx + $length -ge $shortestLength )
            {
                $length = $shortestLength - $startIdx
            }

            Write-Verbose ('{0} Current {1}' -f $linePrefix,$currentTaskXml.Substring($startIdx,$length))
            Write-Verbose ('{0} Desired {1}' -f $linePrefix,$desiredTaskXml.Substring($startIdx,$length))
            if( $length -eq 70 )
            {
                Write-Verbose ('{0}         -----------------------------------^' -f $linePrefix)
            }
            return $false
        }
        else
        {
            Write-Verbose ('[{0}] Task XML unchanged' -f $Name)
        }

        if( $TaskCredential )
        {
            $resourceUserName = $resource.TaskCredential | ForEach-Object { Resolve-CIdentityName -Name $_ }
            $desiredUserName = $TaskCredential.UserName | ForEach-Object { Resolve-CIdentityName -Name $_ }
            if( $resourceUserName -ne $desiredUserName )
            {
                Write-Verbose ('[{0}] [TaskCredential] {1} != {2}' -f $Name,$resourceUserName,$desiredUserName) -Verbose
                return $false
            }
        }

        return $true
    }
    else
    {
        if( $resource.Ensure -eq 'Present' )
        {
            Write-Verbose ('[{0}] Found' -f $Name)
            return $false
        }

        Write-Verbose ('[{0}] Not found' -f $Name)
        return $true
    }
}

Export-ModuleMember -Function *
