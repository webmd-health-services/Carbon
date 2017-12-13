
function New-WhiskeyContextObject
{
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $context = [pscustomobject]@{
                                    ApiKeys = @{ };
                                    BuildRoot = '';
                                    ByBuildServer = $false;
                                    ByDeveloper = $true;
                                    BuildMetadata = (New-WhiskeyBuildMetadataObject);
                                    Configuration = @{ };
                                    ConfigurationPath = '';
                                    Credentials = @{ }
                                    DownloadRoot = '';
                                    Environment = '';
                                    OutputDirectory = '';
                                    PipelineName = '';
                                    Publish = $false;
                                    RunMode = 'Build';
                                    TaskName = '';
                                    TaskIndex = -1;
                                    TaskDefaults = @{ };
                                    Temp = '';
                                    Variables = @{ };
                                    Version = (New-WhiskeyVersionObject);
                                }
    $context | Add-Member -MemberType ScriptMethod -Name 'ShouldClean' -Value { return $this.RunMode -eq 'Clean' }
    $context | Add-Member -MemberType ScriptMethod -Name 'ShouldInitialize' -Value { return $this.RunMode -eq 'Initialize' }

    return $context
}