[CmdletBinding()]
param(
    # The name of the account you wish to download artifacts from
    [String] $AccountName = $env:APPVEYOR_ACCOUNT_NAME,

    # The name of the project you wish to download artifacts from
    [String] $ProjectName = $env:APPVEYOR_PROJECT_SLUG,

    [Parameter(Mandatory)]
    [String] $Token,

    # If you have multiple build jobs, specify which job you wish to retrieve the artifacts from
    [Parameter(Mandatory)]
    [String] $JobName,

    # URL of Appveyor API. You normally shouldn't need to change this.
    [String] $ApiUrl = 'https://ci.appveyor.com/api'
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'

$headers = @{ 'Content-type' = 'application/json' }

if ($Token)
{
    $headers['Authorization'] = "Bearer $token"
}

$projectUrl = "$($ApiUrl)/projects/$($AccountName)/$($ProjectName)"
Write-Verbose "Project URL   $($projectUrl)"


$project = Invoke-RestMethod -Method Get -Uri $projectUrl -Headers $headers

if (-not ($project | Get-Member -Name 'build') -and -not ($project.build | Get-Member -Name 'jobs'))
{
    Write-Error 'No jobs found for this project or the project and/or account name was incorrectly specified'
    exit 1
}

if (($project.build.jobs.count -gt 1) -and -not $JobName)
{
    $msg = 'Multiple Jobs found for the latest build. Please specify the -JobName paramter to select which job you ' +
           'want the artifacts for.'
    Write-Error $msg
    exit 1
}

$job = $project.build.jobs | Where-Object 'Name' -EQ $JobName | Select-Object -First 1

if (-not $job)
{
    Write-Error "Unable to find job ""$($JobName)"" within the latest specified build. Did you spell it correctly?"
    exit 1
}

$artifactsUrl = "$($ApiUrl)/buildjobs/$($job.jobId)/artifacts"
Write-Verbose "Artifact URL  $($artifactsUrl)"
$artifacts = Invoke-RestMethod -Method Get -Uri $artifactsUrl -Headers $headers

$zipFileName = $artifacts | Where-Object 'fileName' -Like 'Carbon*.zip' | Select-Object -ExpandProperty 'fileName'
if (-not $zipFileName)
{
    $msg = 'Unable to download Carbon ZIP file artifact because it does not exist.'
    Write-Error -Message $msg
    exit 1
}

$zipPath = Join-Path -Path $PSScriptRoot -ChildPath $zipFileName

$zipUrl = "$($ApiUrl)/buildjobs/$($job.jobId)/artifacts/$($zipFileName)"
Write-Information "Downloading $($zipUrl) to $($zipPath)."

Invoke-RestMethod -Method Get -Uri $zipUrl -OutFile $zipPath -Headers $headers

Rename-Item -Path 'Carbon' -NewName 'Carbon.orig'
Rename-Item -Path 'examples' -NewName 'examples.orig'

Write-Information "Expanding $($zipPath | Resolve-Path -Relative) to $($PSScriptRoot | Resolve-Path -Relative)."
Expand-Archive -Path $zipFileName -DestinationPath $PSScriptRoot

Remove-Item -Path $zipFileName
