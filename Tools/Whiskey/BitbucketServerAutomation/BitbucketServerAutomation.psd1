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

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'BitbucketServerAutomation.psm1'

    # Version number of this module.
    ModuleVersion = '0.3.0'

    # ID used to uniquely identify this module
    GUID = 'ef458b99-5fc4-4802-99a7-0604b71e3dd7'

    # Author of this module
    Author = 'WebMD Health Services'

    # Company or vendor of this module
    CompanyName = 'WebMD Health Services'

    # Copyright statement for this module
    Copyright = '(c) 2016 WebMD Health Services. All rights reserved.'

    # Description of the functionality provided by this module
    Description = @'
The Bitbucket Server Automation module is used to interact with Bitbucket Server.
'@

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @( 
                            'Formats\Atlassian.Bitbucket.Server.ProjectInfo.ps1xml',
                            'Formats\Atlassian.Bitbucket.Server.RepositoryInfo.ps1xml' 
                        )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module
    FunctionsToExport = @( 
                            'Get-BBServerBranch',
                            'Get-BBServerCommitBuildStatus',
                            'Get-BBServerFile',
                            'Get-BBServerProject',
                            'Get-BBServerPullRequestSetting',
                            'Get-BBServerRepository', 
                            'Get-BBServerTag',
                            'Invoke-BBServerRestMethod',
                            'Move-BBServerRepository',
                            'New-BBServerBranch',
                            'New-BBServerConnection', 
                            'New-BBServerProject',
                            'New-BBServerRepository', 
                            'New-BBServerTag',
                            'Remove-BBServerRepository',
                            'Rename-BBServerRepository',
                            'Set-BBServerCommitBuildStatus',
                            'Set-BBServerDefaultBranch',
                            'Set-BBServerPullRequestSetting' )

    # Cmdlets to export from this module
    CmdletsToExport = '*'

    # Variables to export from this module
    #VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'git', 'bitbucket', 'bitbucket-server', 'scm', 'devops', 'pipeline', 'atlassian' )

            # A URL to the license for this module.
            LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/webmd-health-services/BitbucketServerAutomation'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
* Added `Get-BBServerPullRequestSetting` function for getting the pull request settings for a repository.
* Added `Set-BBServerPullRequestSetting` function for setting the pull request settings for a repository.
* Added `Move-BBServerRepository` function for moving repositories between projects.
* Added `Rename-BBServerRepository` function for renaming an existing repository.
* Fixed: in some failure scenarios, the web requests error handler fails.
'@

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
