
function New-WhiskeyBuildMetadataObject
{
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $info = [pscustomobject]@{
                                BuildNumber = 0;
                                BuildID = '';
                                BuildServerName = '';
                                BuildUri = '';
                                JobName = '';
                                JobUri = '';
                                ScmBranch = '';
                                ScmCommitID = '';
                                ScmUri = '';
                            }
    $info |
        Add-Member -MemberType ScriptProperty -Name 'IsAppVeyor' -Value { return $this.BuildServerName -eq 'AppVeyor' } -PassThru |
        Add-Member -MemberType ScriptProperty -Name 'IsDeveloper' -Value { return $this.BuildServerName -eq '' } -PassThru |
        Add-Member -MemberType ScriptProperty -Name 'IsBuildServer' -Value { return -not $this.IsDeveloper } -PassThru |
        Add-Member -MemberType ScriptProperty -Name 'IsJenkins' -Value { return $this.BuildServerName -eq 'Jenkins' } -PassThru |
        Add-Member -MemberType ScriptProperty -Name 'IsTeamCity' -Value { return $this.BuildServerName -eq 'TeamCity' } -PassThru
}
