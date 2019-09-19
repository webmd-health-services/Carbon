
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
        Write-Debug -Message ('{0} > powershell.exe {1}' -f (Get-Location).ProviderPath,$CommandLine)
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
