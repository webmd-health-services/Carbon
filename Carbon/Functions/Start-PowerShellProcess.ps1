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

function Start-PowerShellProcess
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $CommandLine,

        [Parameter(Mandatory=$true)]
        [pscredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $outFile = '{0}-{1}-stdout' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
    $outFile = Join-Path -Path $env:TEMP -ChildPath $outFile
    Write-Debug $outFile
    '' | Set-Content -Path $outFile

    $errFile = '{0}-{1}-stderr' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
    $errFile = Join-Path -Path $env:TEMP -ChildPath $errFile
    Write-Debug $errFile
    '' | Set-Content -Path $errFile

    try
    {
        $p = Start-Process -FilePath "powershell.exe" `
                           -ArgumentList $CommandLine `
                           -Credential $Credential `
                           -RedirectStandardOutput $outFile `
                           -RedirectStandardError $errFile `
                           -Wait `
                           -WindowStyle Hidden `
                           -PassThru

        $p.WaitForExit()

        $stdOut = Get-Content -Path $outFile -Raw
        if( $stdOut )
        {
            Write-Verbose -Message $stdOut
        }

        $stdErr = Get-Content -Path $errFile -Raw
        if( $stdErr )
        {
            Write-Error -Message $stdErr
            return
        }

        if( $p.ExitCode -ne 0 )
        {
            Write-Error -Message ('Unknown error running PowerShell as user {0}: exit code {1}{2}{3}' -f $Credential.UserName,$p.ExitCode,([Environment]::NewLine),$stdOut)
            return
        }

        if( $stdOut )
        {
            return Get-Content -Path $outFile
        }
    }
    finally
    {
        Remove-Item -Path $outFile,$errFile -ErrorAction SilentlyContinue
    }
}