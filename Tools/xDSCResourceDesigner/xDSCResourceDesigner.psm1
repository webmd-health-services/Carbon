 #Requires -RunAsAdministrator
# A global variable that contains localized messages.
data LocalizedData
{
# culture="en-US"
ConvertFrom-StringData @'
ModuleParsingError=There was an error parsing the module file {0}
SchemaEncodingNotSupportedPrompt=The encoding for the schema file is not supported. Convert to Unicode?
SchemaEncodingNotSupportedError=The encoding for the schema file is not supported. Please use Unicode or ASCII.
SchemaFileReEncodingVerbose=Re-encoding the schema file in Unicode.
SchemaModuleReadError=Property {0} declared as Read in the schema, cannot be a parameter in the module.
SchemaModuleAttributeError=Property {0} has a different attribute in the schema than in the module.
SchemaModuleTypeError=Property {0} has a different type in the schema than in the module.
SchemaModuleValidateSetDiscrepancyError=The schema and module don't both have the ValidateSet tag for property {0}.
SchemaModuleValidateSetCountError=The ValidateSet tag has a different number of items between the schema and module.
SchemaModuleValidateSetItemError=The ValidateSet item {1} for property {0} in the schema was not found in the module.
ImportTestSchemaVerbose=The schema file has been verified.
ImportReadingPropertiesVerbose=Reading the properties from the schema file.
SchemaPathValidVerbose=The path to the schema file has been verified.
SchemaMofCompCheckVerbose=The schema file has passed mofcomp's syntax check.
SchemaDscContractsVerbose=Testing the schema file's compliance to Desired State Configuration's contracts.
AdminRightsError=You do not have Administrator rights to run this script. Please re-run this script as an Administrator.
PathIsInvalidError=There was an error creating the folder {0}.
SchemaNotFoundInDirectoryError=The expected file {0} was not found.
ModuleNotFoundInDirectoryError=The expected file {0} was not found.
ModuleNameNotFoundError=No module with the name {0} was found in $env:PSModulePath.
NewResourceKeyVerbose=Successfully found a property with the attribute Key.
NewResourceNameVerbose=Resource Name was found to be valid.
NewModuleManifestPathVerbose=The module manifest was created for the specified module name.
DefaultAttribute=The attribute for the property was set to the default value: "Write"
NewResourceUniqueVerbose=All of the properties had unique names.
NewResourcePathVerbose=The output path was valid.
NewResourceSuccessVerbose=The generated resource was tested and found acceptable.
TestResourceIndividualSuccessVerbose=The schema.mof and .psm1 files were both indivually correct.
TestResourceTestSchemaVerbose=Testing the schema.mof file.
TestResourceTestModuleVerbose=Testing the .psm1 file.
TestResourceGetMandatoryVerbose=Result of testing Get-TargetResource for it's mandatory properties: {0}.
TestResourceSetNoReadsVerbose=Result of testing Set-TargetResource for no read properties: {0}.
TestResourceGetNoReadsVerbose=Result of testing Get-TargetResource for no read properties: {0}.
ResourceError=Test-xDscResource detected an error, so the generated files will be removed.
KeyArrayError=Key Properties can not be Arrays.
ValidateSetTypeError=ValidateSet item {0} did not match type {1}.
InvalidValidateSetUsageError=ValidateSet can not be used for Arrays, PSCredentials, and Hashtable.
InvalidPropertyNameError=Property name {0} must start with a character and contain only characters, digits, and underscores.
InvalidPropertyDescriptionError=Property description {0} must contain only characters, digits, underscores and spaces.
PropertyNameTooLongError=Property name {0} is longer than 255 characters.
InvalidResourceNameError=Resource name {0} must start with a character and contain only characters, digits, and underscores.
ResourceNameTooLongError=Resource name {0} is longer than 255 characters.
NoKeyError=At least one DscResourceProperty must have the attribute Key.
NonUniqueNameError=Multiple DscResourceProperties share the name {0}.
OverWriteManifestOperation=OverWrite manifest file.
ManifestNotOverWrittenWarning=The manifest file {0} was not updated.
OverWriteSchemaOperation=OverWrite schema.mof file.
SchemaNotOverWrittenWarning=The schema.mof file {0} was not updated.
OverWriteModuleOperation=OverWrite module file.
ModuleNotOverWrittenWarning=The module file {0} was not updated.
UsingWriteVerbose=Use this cmdlet to deliver information about command processing.
UsingWriteDebug=Use this cmdlet to write debug information while troubleshooting.
IfRebootRequired=Include this line if the resource requires a system reboot.
BadSchemaPath=The parameter -Schema must be a path to a .schema.mof file.
BadResourceMOdulePath=The parameter -ResourceModule must be a path to a .psm1 or .dll file.
SchemaParseError=There was an error parsing the Schema file. 
GetCimClass-Error=There was an error retrieving the Schema.
ImportResourceModuleError=There was an error importing the Resource Module.
KeyFunctionsNotDefined=The following functions were not found: {0}.
MissingOMI_BaseResourceError=The Schema must be defined as "class {0} : OMI_BaseResource".
ClassNameSchemaNameDifferentError=The Class name {0} does not match the Schema name {1}.
UnsupportedMofTypeError=In property {0}, the mof type {1} is not supported.
ValueMapValuesPairError=In property {0}, the qualifiers "ValueMap" and "Values" must be used together and specify identical values.
NoKeyTestError=At least one property must have the qualifier "Key".
InvalidEmbeddedInstance=In property {0}, only MSFT_Credential and MSFT_KeyValuePair are allowed as EmbeddedInstances.
EmbeddedInstanceCimTypeError=In property {0}, all EmbeddedInstances must be encoded as Strings.
GetTargetResourceOutWarning=Get-TargetResource should return a [Hashtable] mapping all schema properties to their values. Prepend the param block with [OutputType([Hashtable])].
GetTargetResourceOutError=Get-TargetResource should return a [Hashtable] mapping all schema properties to their values. Prepend the param block with [OutputType([Hashtable])].
SetTargetResourceOutError=Set-TargetResource should not return anything.
TestTargetResourceOutWarning=Test-TargetResource should return a [boolean]. Prepend the param block with [OutputType([Boolean])].
TestTargetResourceOutError=Test-TargetResource should return a [boolean]. Prepend the param block with [OutputType([Boolean])].
SetTestNotIdenticalError=Set-TargetResource and Test-TargetResource should take identical parameters.
SetTestMissingParameterError=Set-TargetResource and Test-TargetResource must take identical parameters. {0} is missing parameter {1} from {2}.
ModuleValidateSetError=Parameter {0} had a different ValidateSet attribute between function {1} and {2}.
ModuleMandatoryError=Parameter {0} had a different value for the Mandatory flag between function {1} and {2}.
ModuleTypeError=Parameter {0} had a different type between function {1} and {2}.
NoKeyPropertyError={0} must take at least one mandatory, non array parameter.
UnsupportedTypeError=In function {0}, the type {1} of parameter {2} is not supported.
SetTestMissingGetParameterError=Set-TargetResource and Test-TargetResource are missing the parameter {0} in Get-TargetResource.
GetParametersDifferentError=Set-TargetResource and Test-TargetResource must include all of the parameters from Get-TargetResource and their attributes must be identical.
MissingAttributeError=Property {0} must be tagged as either Key, Required, Write, or Read.
IllegalAttributeCombinationError=For property {0}, the attribute Read can not be used with any other property.
GetMissingKeyOrRequiredError=The function Get-TargetResource must take all Key and Required properties, and they must be mandatory. There was an issue with property {0}.
SetAndTestMissingParameterError=The functions Set-TargetResource and Test-TargetResource must take all Key, Required and Write properties. There is an issue with the parameter {0} defined in the schema.
SetAndTestExtraParameterError=The functions Set-TargetResource and Test-TargetResource have an extra parameter {0} that is not defined in the schema.
GetTakesReadError=The function Get-TargetResource can not take the read property {0}, defined in the schema, as a parameter. 
SetTestTakeReadError=The functions Set-TargetResource and Test-TargetResource can not take the read property {0} defined in the schema as a parameter.
'@
}

#Import-LocalizedData LocalizedData -FileName xDSCResourceDesigner.strings.psd1

Add-Type -ErrorAction Stop -TypeDefinition @" 
        namespace Microsoft.PowerShell.xDesiredStateConfiguration
        {
            public enum DscResourcePropertyAttribute
            {
                Key = 0,
                Required = 1,
                Read = 2,
                Write = 3
            }
            public class DscResourceProperty
            {
                private System.String name;

                public System.String Name
                {
                    get
                    {
                        return name;
                    }

                    set
                    {
                        name = value;
                    }
                }

                private System.String type;

                public System.String Type
                {
                    get
                    {
                        return type;
                    }

                    set
                    {
                        type = value;
                    }
                }

                private DscResourcePropertyAttribute attribute;

                public DscResourcePropertyAttribute Attribute
                {
                    get
                    {
                        return attribute;
                    }

                    set
                    {
                        attribute = value;
                    }
                }

                private System.String[] validateSet;

                public System.String[] ValidateSet
                {
                    get
                    {
                        return validateSet;
                    }
                
                    set
                    {
                        validateSet = value;
                    }
                }

                private System.String description;

                public System.String Description
                {
                    get
                    {
                        return description;
                    }
                
                    set
                    {
                        description = value;
                    }
                }
            }
        }
"@

[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::add("DscResourcePropertyAttribute","Microsoft.PowerShell.xDesiredStateConfiguration.DscResourcePropertyAttribute")
[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::add("DscResourceProperty","Microsoft.PowerShell.xDesiredStateConfiguration.DscResourceProperty")

$TypeMap = @{
        "Uint8"   = [System.Byte];
        "Uint16"  = [System.UInt16];
        "Uint32"  = [System.Uint32];
        "Uint64"  = [System.UInt64];
        "Sint8"   = [System.SByte];
        "Sint16"  = [System.Int16];
        "Sint32"  = [System.Int32];
        "Sint64"  = [System.Int64];
        "Real32"  = [System.Single];
        "Real64"  = [System.Double];
        "Char16"  = [System.Char];
        "String"  = [System.String];
        "Boolean" = [System.Boolean];
        "DateTime"= [System.DateTime];
        
        "Hashtable"    = [System.Collections.Hashtable];
        "PSCredential" = [PSCredential];

        "Uint8[]"   = [System.Byte[]];
        "Uint16[]"  = [System.UInt16[]];
        "Uint32[]"  = [System.Uint32[]];
        "Uint64[]"  = [System.UInt64[]];
        "Sint8[]"   = [System.SByte[]];
        "Sint16[]"  = [System.Int16[]];
        "Sint32[]"  = [System.Int32[]];
        "Sint64[]"  = [System.Int64[]];
        "Real32[]"  = [System.Single[]];
        "Real64[]"  = [System.Double[]];
        "Char16[]"  = [System.Char[]];
        "String[]"  = [System.String[]];
        "Boolean[]" = [System.Boolean[]];
        "DateTime[]"= [System.DateTime[]];
        
        "Hashtable[]"    = [System.Collections.Hashtable[]];
        "PSCredential[]" = [PSCredential[]];
    }

$EmbeddedInstances = @{
    "Hashtable"    = "MSFT_KeyValuePair";
    "PSCredential" = "MSFT_Credential";

    "Hashtable[]"    = "MSFT_KeyValuePair";
    "PSCredential[]" = "MSFT_Credential";

    "HashtableArray"    = "MSFT_KeyValuePair";
    "PSCredentialArray" = "MSFT_Credential";
}

$NameRegex = "^[a-zA-Z][\w_]*$"
$DescriptionRegex = "^[\w\s]*$"
$NameMaxLength = 255 #This number is hardcoded into the localization text as 255

$commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties() | % Name

<#
.SYNOPSIS 
Creates a DscResourceProperty to be used by New-xDscResource.

.DESCRIPTION
Takes all of the given arguments and constructs a DscResourceProperty object to be used by New-xDscResource.

.PARAMETER Name
Specifies the property name.

.PARAMETER Type
Specifies the property type.

.PARAMETER Attribute
Specifies the property attribute.

.PARAMETER ValidateSet
Optional, Specifies the valid values for the property.

.PARAMETER Description
Optional, Specifies a description for the property.

.OUTPUTS
DscResourceProperty. Wraps all of the arguments into a type object.

.EXAMPLE
C:\PS> New-xDscResourceProperty -Name "Ensure" -Type "String" -Attribute Write -ValidateSet "Present","Absent" -Description "Ensure Present or Absent"
Name        : Ensure
Type        : String
Attribute   : Write
ValidateSet : {Present, Absent}
Description : Ensure Present or Absent
#>
function New-xDscResourceProperty
{
    [CmdletBinding()]
    [OutputType([DscResourceProperty])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName=$true)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 1)]
        [ValidateSet("Uint8","Uint16","Uint32","Uint64",`
                     "Sint8","Sint16","Sint32","Sint64",`
                     "Real32","Real64","Char16","String",`
                     "Boolean","DateTime","Hashtable",`
                     "PSCredential",`
                     "Uint8[]","Uint16[]","Uint32[]","Uint64[]",`
                     "Sint8[]","Sint16[]","Sint32[]","Sint64[]",`
                     "Real32[]","Real64[]","Char16[]","String[]",`
                     "Boolean[]","DateTime[]","Hashtable[]",`
                     "PSCredential[]")]
        [System.String]
        $Type,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourcePropertyAttribute]
        $Attribute,

        [System.String[]]
        $ValidateSet,

        [System.String]
        $Description
    )
    
    if ((Test-TypeIsArray $Type) -and [DscResourcePropertyAttribute]::Key -eq $Attribute)
    {
        $errorId = "KeyArrayError"
        Write-Error $localizedData[$errorId] `
            -ErrorId $errorId -ErrorAction Stop
    }

    if ($ValidateSet -and ((Test-TypeIsArray $Type) -or $EmbeddedInstances.ContainsKey($Type)))
    {
        Write-Error ($localizedData.InvalidValidateSetUsageError) `
                   -ErrorId "InvalidValidateSetUsageError" -ErrorAction Stop
    }

    if ($ValidateSet -and (-not $ValidateSet.Length -le 0))
    {
        $ValidateSet | foreach {

            if (-not ([System.Management.Automation.LanguagePrimitives]::`
                        TryConvertTo($_, $TypeMap[$Type], [ref]$null)))
            {
                Write-Error ($localizedData.ValidateSetTypeError -f $_,$Type) `
                        -ErrorId "ValidateSetTypeError" -ErrorAction Stop
            }
        }
    }

    if (-not ($Description -cmatch $DescriptionRegex))
    {
        Write-Error ($localizedData.InvalidPropertyDescriptionError) `
                -ErrorId "InvalidPropertyDescriptionError" -ErrorAction Stop
    }

    Test-Name $Name "Property"

    $hash = @{
        Name=$Name
        Type=$Type
        Attribute=$Attribute
        ValidateSet=$ValidateSet
        Description=$Description
    }

    $Property = New-Object "DscResourceProperty" -Property $hash
    
    return $Property
}

function Test-Name
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $name,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [ValidateSet("Resource","Property")]
        [System.String]
        $errorType
    )

    if (-not ($Name -cmatch $NameRegex))
    {
        $errorId = "Invalid" + $errorType + "NameError"

        Write-Error ($localizedData[$errorId] -f $Name) `
                        -ErrorId $errorId -ErrorAction Stop
    }

    if ($Name.Length -gt $NameMaxLength)
    {
        $errorId = $errorType + "NameTooLongError"

        Write-Error ($localizedData[$errorId] -f $Name) `
                        -ErrorId $errorId -ErrorAction Stop
    }

}

function Test-PropertiesForResource
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [DscResourceProperty[]]
        $Properties
    )

    #Check to make sure $Properties contains a [Key]
    $key = $false
    foreach ($property in $Properties)
    {
        if ([DscResourcePropertyAttribute]::Key -eq $property.Attribute)
        {
            $key = $true
            break
        }
    }

    if (-not $key)
    {
        Write-Error ($localizedData.NoKeyError) `
                        -ErrorId "NoKeyError" -ErrorAction Stop
    }
    Write-Verbose $localizedData["NewResourceKeyVerbose"]

    #Check to make sure all variables have unique names
    $unique = $true
    $Names = @{}
    foreach ($property in $Properties)
    {
        if ($Names[$property.Name])
        {
            $unique = $property.Name
            break
        }

        $Names.Add($property.Name, $true)
    }

    # $unique will either be $true, or the string containing the non unique name
    if (-not ($unique -eq $true))
    {
        Write-Error ($localizedData.NonUniqueNameError -f $unique) `
                        -ErrorId "NonUniqueNameError" -ErrorAction Stop
    }
    Write-Verbose $localizedData["NewResourceUniqueVerbose"]
    
    return $true
}

<#
.SYNOPSIS 
Creates a DscResource based on the given arguments.

.DESCRIPTION
Creates a .psd1, .psm1, and .schema.mof file representing a Dsc Resource based on the properties and values passed in.

.PARAMETER Name
Specifies the resource name.

.PARAMETER Property
Specifies the properties of the resource.

.PARAMETER Path
Specifies where to create the output files.

.PARAMETER ClassVersion
Optional, Specifies the version number of the resource.

.PARAMETER FriendlyName
Optional, Specifies the friendly name of the resource. Defaults to the same as the name.

.PARAMETER Force
Optional, determines if the cmdlet overwrites files without prompting.

.EXAMPLE
C:\PS> New-xDscResource -Name "UserResource" -Property $UserName,$Ensure,$Password -Path "$pshome\Modules\UserResource" -ClassVersion 1.0 -FriendlyName "User" -Force
#>
function New-xDscResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName=$true)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true)]
        [DscResourceProperty[]]
        $Property,

        [Parameter(
            Mandatory = $false,
            Position = 2)]
        [System.String]
        $Path = ".",

        
        [Parameter(
            Mandatory = $false,
            Position = 3)]
        [System.String]
        $ModuleName,

        [System.Version]
        $ClassVersion = "1.0.0.0",

        [System.String]
        $FriendlyName = $Name,

        [Switch]
        $Force
    )

    
    $null = Test-AdministratorPrivileges
    Test-Name $Name "Resource"
    Write-Verbose $localizedData["NewResourceNameVerbose"]

    $null = Test-PropertiesForResource $Property 
    
    # Check if the given path exists, if not create it. 
    if (-not (Test-Path $Path -PathType Container))
    {
        New-Item $Path -type Directory -ErrorVariable ev -ErrorAction SilentlyContinue

        if ($ev)
        {
            Write-Error ($localizedData.PathIsInvalidError -f $Path) `
                        -ErrorId "PathIsInvalidError" -ErrorAction Stop
        }
    }

    if($moduleName)
    {
        $Path = Join-Path $Path $moduleName;
        if(-not (Test-Path $Path -PathType Container))
        {
            New-Item $Path -ItemType Directory -ErrorVariable ev -ErrorAction SilentlyContinue
            if($ev)
            {
                 Write-Error ($localizedData.PathIsInvalidError -f $fullPath) `
                        -ErrorId "PathIsInvalidError" -ErrorAction Stop
            }
        }
        $manifestPath = Join-Path $Path "$moduleName.psd1"
        if(-not (Test-Path $manifestPath -PathType Leaf))
        {
            New-ModuleManifest -Path $manifestPath -ErrorVariable ev -ErrorAction SilentlyContinue
            if($ev)
            {
                Write-Error ($localizedData.PathIsInvalidError -f $fullPath) `
                        -ErrorId "PathIsInvalidError" -ErrorAction Stop
                
            }
            Write-Verbose $localizedData["NewModuleManifestPathVerbose"]
        }
    }

    $fullPath = Join-Path $Path "DSCResources"

    # Check if $Path/DSCResources exists, if not create it.
    if (-not (Test-Path $fullPath -PathType Container))
    {
        New-Item $fullPath -type Directory -ErrorVariable ev -ErrorAction SilentlyContinue

        if ($ev)
        {
            Write-Error ($localizedData.PathIsInvalidError -f $fullPath) `
                        -ErrorId "PathIsInvalidError" -ErrorAction Stop
        }
    }

    Write-Verbose $localizedData["NewResourcePathVerbose"]

    $fullPath = Join-Path $fullPath $Name
    # Check if $Path/DSCResources/$Name exists, if not create it.
    if (-not (Test-Path $fullPath -PathType Container))
    {
        New-Item $fullPath -type Directory -ErrorVariable ev -ErrorAction SilentlyContinue

        if ($ev)
        {
            Write-Error ($localizedData.PathIsInvalidError -f $fullPath) `
                        -ErrorId "PathIsInvalidError" -ErrorAction Stop
        }
    }
    
    #New-DscManifest $Name $fullPath $ClassVersion -Force:$Force -ParentPSCmdlet $PSCmdlet -Confirm

    New-DscSchema $Name $fullPath $Property $ClassVersion -FriendlyName:$FriendlyName  -Force:$Force -ParentPSCmdlet $PSCmdlet -Confirm

    New-DscModule $Name $fullPath $Property -Force:$Force -ParentPSCmdlet $PSCmdlet -Confirm

    $schemaPath = Join-Path $fullPath "$Name.schema.mof"
    $modulePath = Join-Path $fullPath "$Name.psm1"
    #$manifestPath = Join-Path $fullPath "$Name.psd1"

    if (-not (Test-xDscResource $fullPath))
    {
        Write-Error ($localizedData.ResourceError) `
                        -ErrorId "ResourceError" -ErrorAction Stop

        Remove-Item $schemaPath
        Remove-Item $modulePath
        #Remove-Item $manifestPath
    }
    Write-Verbose $localizedData["NewResourceSuccessVerbose"]
}

function New-DscManifest
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(
            Mandatory,
            Position = 1)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.String]
        $Path,

        [parameter(
            Mandatory,
            Position = 3)]
        [System.Version]
        $ClassVersion,

        [switch]
        $Force,

        [System.Management.Automation.PSCmdlet]
        $ParentPSCmdlet = $PSCmdlet
    )

    $ManifestPath = Join-Path $path "$name.psd1"

    $ManifestExists = Test-Path $ManifestPath -PathType Leaf

    if (-not $ManifestExists -or $Force -or $ParentPSCmdlet.ShouldProcess($ManifestPath, $localizedData.OverWriteManifestOperation))
    {
        New-ModuleManifest `
            -Path $ManifestPath `
            -FunctionsToExport "Get-TargetResource","Set-TargetResource","Test-TargetResource" `
            -ModuleVersion $ClassVersion `
            -PowerShellVersion 3.0 `
            -ClrVersion 4.0 `
            -NestedModules "$Name.psm1" `
            -Confirm:$false
    }
    else
    {
        Write-Warning ($localizedData.ManifestNotOverWrittenWarning -f $ManifestPath)
    }

}

function New-DscSchema
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(
            Mandatory,
            Position = 1)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.String]
        $Path,

         [parameter(
            Mandatory = $true,
            Position = 3)]
        [DscResourceProperty[]]
        $Parameters,
        
        [parameter(
            Mandatory,
            Position = 4)]
        [System.Version]
        $ClassVersion,

        [parameter(
            Position = 5)]
        [System.String]
        $FriendlyName,

        [switch]
        $Force,

        [System.Management.Automation.PSCmdlet]
        $ParentPSCmdlet = $PSCmdlet
    )   

    $Schema = New-Object -TypeName System.Text.StringBuilder

    Add-StringBuilderLine $Schema

    Add-StringBuilderLine $Schema "[ClassVersion(`"$ClassVersion`"), FriendlyName(`"$FriendlyName`")]"
    Add-StringBuilderLine $Schema "class $Name : OMI_BaseResource"
    Add-StringBuilderLine $Schema "{"

    foreach ($parameter in $Parameters)
    {
        Add-StringBuilderLine $Schema (New-DscSchemaParameter $parameter)
    }

    Add-StringBuilderLine $Schema "};"

    $SchemaPath = Join-Path $Path "$name.schema.mof"
    $SchemaExists = Test-Path $SchemaPath -PathType Leaf

    if (-not $SchemaExists -or $Force -or $ParentPSCmdlet.ShouldProcess($SchemaPath, $localizedData.OverWriteSchemaOperation))
    {
        $Schema.ToString() | Out-File -FilePath $SchemaPath -Force -Confirm:$false
    }
    else
    {
        Write-Warning ($localizedData.SchemaNotOverWrittenWarning -f $SchemaPath)
    }
    
}

# Given a type string (Uint8,...,Uint8[]...,Uint8Array) return the version without the "[]" or "Array" characters
# If the type is PSCredential or Hashtable (or the array versions) returns "String"
function Get-TypeNameForSchema
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [String]
        $Type
    )

    if ($EmbeddedInstances.ContainsKey($Type))
    {
        return "String"
    }

    $null = $Type -cmatch "^([a-zA-Z][\w_]*?)(\[\]|Array)?$"
    
    return $Matches[1]
}

function Test-TypeIsArray
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [String]
        $Type
    )
    # Returns true if $Type ends with "[]"
    return ($Type -cmatch "^[a-zA-Z][\w_]*\[\]$")
}

function New-DscSchemaParameter
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [DscResourceProperty]
        $Parameter
    )

    $SchemaEntry = New-Object -TypeName System.Text.StringBuilder

    Add-StringBuilderLine $SchemaEntry "`t[" -Append
    Add-StringBuilderLine $SchemaEntry $Parameter.Attribute -Append
    
    if ($EmbeddedInstances.ContainsKey($Parameter.Type))
    {
        Add-StringBuilderLine $SchemaEntry ", EmbeddedInstance(`"" -Append
        Add-StringBuilderLine $SchemaEntry $EmbeddedInstances[$Parameter.Type] -Append
        Add-StringBuilderLine $SchemaEntry "`")" -Append
    }

    if ($Parameter.Description)
    {
        Add-StringBuilderLine $SchemaEntry ", Description(`"" -Append
        Add-StringBuilderLine $SchemaEntry $Parameter.Description -Append
        Add-StringBuilderLine $SchemaEntry "`")" -Append
    }


    if ($Parameter.ValidateSet)
    {
        Add-StringBuilderLine $SchemaEntry ", ValueMap{" -Append

        $CommaList = New-DelimitedList $Parameter.ValidateSet -String:($Parameter.Type -eq "String")

        Add-StringBuilderLine $SchemaEntry $CommaList -Append
        Add-StringBuilderLine $SchemaEntry "}, Values{" -Append
        Add-StringBuilderLine $SchemaEntry $CommaList -Append
        Add-StringBuilderLine $SchemaEntry "}" -Append
    }

   
    Add-StringBuilderLine $SchemaEntry "] " -Append

    Add-StringBuilderLine $SchemaEntry (Get-TypeNameForSchema $Parameter.Type) -Append

    Add-StringBuilderLine $SchemaEntry " " -Append

    Add-StringBuilderLine $SchemaEntry ($Parameter.Name) -Append

    if (Test-TypeIsArray $Parameter.Type)
    {
        Add-StringBuilderLine $SchemaEntry "[]" -Append
    }

    Add-StringBuilderLine $SchemaEntry ";" -Append

    return $SchemaEntry.ToString()

}

function New-DelimitedList
{
    param
    (
        [System.Object[]]
        $list,

        [Switch]
        $String,

        [String]
        $Separator = ","
    )

    $CommaList = New-Object -TypeName System.Text.StringBuilder

    for ($i = 0; $i -lt $list.Count; $i++)
    {
        $curItem = $list[$i]

        # If the given Parameter is type string, is that the only time
        #  the validateSet items need to be wrapped in quotes?
        if ($String)
        {
            Add-StringBuilderLine $CommaList "`"" -Append
            Add-StringBuilderLine $CommaList $curItem -Append
            Add-StringBuilderLine $CommaList "`"" -Append
        }
        else
        {
            Add-StringBuilderLine $CommaList $curItem -Append
        }
            

        if($i -lt ($list.Count -1))
        {
            Add-StringBuilderLine $CommaList $Separator -Append
        }
    }

    Return $CommaList.ToString()
}

function New-DscModule
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Name,
        
        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.String]
        $Path,

        [parameter(
            Mandatory = $true,
            Position = 3)]
        [DscResourceProperty[]]
        $Parameters,
        
        [Switch]
        $Force,
        
        [System.Management.Automation.PSCmdlet]
        $ParentPSCmdlet = $PSCmdlet
    )

    $Module = New-Object -TypeName System.Text.StringBuilder
    
    # Create a function Get-TargetResource
    #   Add all parameters with the Key or Required tags
    Add-StringBuilderLine $Module (New-GetTargetResourceFunction $Parameters)
    
    # Create a function Set-TargetResource
    #    Add all parametes without the Read tag
    Add-StringBuilderLine $Module (New-SetTargetResourceFunction $Parameters)
    
    # Create a function Test-TargetResource
    #    Add all parametes without the Read tag
    Add-StringBuilderLine $Module (New-TestTargetResourceFunction $Parameters)

    Add-StringBuilderLine $Module ("Export-ModuleMember -Function *-TargetResource")

    $ModulePath = Join-Path $Path ($Name + ".psm1")
    
    $ModuleExists = Test-Path $ModulePath -PathType Leaf

    if (-not $ModuleExists -or $Force -or $ParentPSCmdlet.ShouldProcess($ModulePath, $localizedData.OverWriteModuleOperation))
    {
        $Module.ToString() | Out-File -FilePath $ModulePath -Force -Confirm:$false
    }
    else
    {
        Write-Warning ($localizedData.ModuleNotOverWrittenWarning -f $ModulePath)
    }
}

function New-GetTargetResourceFunction
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [DscResourceProperty[]]
        $Parameters,

        [System.String]
        $functionContent
    )

    return New-DscModuleFunction "Get-TargetResource" `
        ($Parameters | Where-Object {([DscResourcePropertyAttribute]::Key -eq $_.Attribute) `
                                    -or ([DscResourcePropertyAttribute]::Required -eq $_.Attribute)})`
        "System.Collections.Hashtable"`
        ($Parameters)`
        -FunctionContent $functionContent

}

function New-SetTargetResourceFunction
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [DscResourceProperty[]]
        $Parameters,

        [System.String]
        $functionContent
    )

    return New-DscModuleFunction "Set-TargetResource" `
        ($Parameters | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)})`
        -FunctionContent $functionContent
}

function New-TestTargetResourceFunction
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [DscResourceProperty[]]
        $Parameters,

        [System.String]
        $functionContent
    )

    return New-DscModuleFunction "Test-TargetResource" `
        ($Parameters | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)})`
        "Boolean"`
        -FunctionContent $functionContent
}

# Given a function name and a set of parameters, 
#  returns a string representation of this function
#  If given the ReturnValues, returns a hashtable consiting of these values
function New-DscModuleFunction
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourceProperty[]]
        $Parameters,

        [parameter(
            Mandatory = $false,
            Position = 3)]
        [System.Type]
        $ReturnType,

        [parameter(
            Mandatory = $false,
            Position = 4)]
        [DscResourceProperty[]]
        $ReturnValues,

        [parameter(
            Mandatory = $false,
            Position = 5)]
        [System.String]
        $FunctionContent
    )


    $Function = New-Object -TypeName System.Text.StringBuilder

    Add-StringBuilderLine $Function "function $Name"
    Add-StringBuilderLine $Function "{"
    Add-StringBuilderLine $Function     "`t[CmdletBinding()]"

    if ($ReturnType)
    {
        Add-StringBuilderLine $Function ("`t[OutputType([" + $ReturnType.FullName +"])]")
    }

    Add-StringBuilderLine $Function     "`tparam"
    Add-StringBuilderLine $Function     "`t("

    for ($i = 0; $i -lt ($Parameters.Count - 1); $i++)
    {
        Add-StringBuilderLine  $Function (New-DscModuleParameter $Parameters[$i])
    }

    #Because every function takes at least the key parameters, 
    # $Parameters is at least size 1
    Add-StringBuilderLine  $Function (New-DscModuleParameter $Parameters[$i] -Last)

    Add-StringBuilderLine  $Function     "`t)"
    
    if ($FunctionContent) # If we are updating an already existing function
    {
        Add-StringBuilderLine $Function $FunctionContent
    }
    else # Add some useful comments
    {
        Add-StringBuilderLine  $Function 

        Add-StringBuilderLine $Function ("`t#Write-Verbose `"" + $localizedData.UsingWriteVerbose + "`"")
        Add-StringBuilderLine $Function
        Add-StringBuilderLine $Function ("`t#Write-Debug `"" + $localizedData.UsingWriteDebug + "`"")
    
        if ($Name.Contains("Set-TargetResource"))
        {
            Add-StringBuilderLine $Function
            Add-StringBuilderLine $Function ("`t#" + $localizedData.IfRebootRequired)
            Add-StringBuilderLine $Function "`t#`$global:DSCMachineStatus = 1"
        }

        Add-StringBuilderLine $Function 
        Add-StringBuilderLine $Function

        if ($ReturnValues)
        {
            Add-StringBuilderLine  $Function (New-DscModuleReturn $ReturnValues)
        }
        elseif ($ReturnType -ne $null)
        {
            Add-StringBuilderLine $Function "`t<#"
            Add-StringBuilderLine $Function "`t`$result = [" -Append
            Add-StringBuilderLine $Function $ReturnType.FullName -Append
            Add-StringBuilderLine $Function "]"
            Add-StringBuilderLine $Function "`t"
            Add-StringBuilderLine $Function "`t`$result"
            Add-StringBuilderLine $Function "`t#>"
        }
    }

    Add-StringBuilderLine  $Function "}"
    if (-not $FunctionContent)
    {
        Add-StringBuilderLine  $Function 
    }
    
    return $Function.ToString()
}

function New-DscModuleParameter
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [DscResourceProperty]
        $Parameter,

        [parameter(
            Mandatory = $false,
            Position = 2)]
        [Switch]
        $Last
    )
    
    $ParameterBuilder = New-Object -TypeName System.Text.StringBuilder

    if (([DscResourcePropertyAttribute]::Key -eq $Parameter.Attribute) `
            -or ([DscResourcePropertyAttribute]::Required -eq $Parameter.Attribute))
    {
        Add-StringBuilderLine $ParameterBuilder "`t`t[parameter(Mandatory = `$true)]"
    }

    if ($Parameter.ValidateSet)
    {
        $ValidateSetProperty = New-Object -TypeName System.Text.StringBuilder
        
        Add-StringBuilderLine $ValidateSetProperty "`t`t[ValidateSet(" -Append

        Add-StringBuilderLine $ValidateSetProperty `
            (New-DelimitedList $Parameter.ValidateSet -String:($Parameter.Type -eq "String")) -Append

        Add-StringBuilderLine $ValidateSetProperty ")]" -Append

        Add-StringBuilderLine $ParameterBuilder $ValidateSetProperty
    }


    $typeString = $TypeMap[$Parameter.Type].ToString()
    Add-StringBuilderLine $ParameterBuilder "`t`t[$TypeString]"

    #Append, so the "," is added on the same line
    Add-StringBuilderLine $ParameterBuilder ("`t`t$"+$Parameter.Name) -Append

    if (-not $Last)
    {
        Add-StringBuilderLine $ParameterBuilder "," 
    }

    return $ParameterBuilder.ToString()
}

function New-DscModuleReturn
{
    param
    (
        [parameter(
            Mandatory = $True,
            Position = 1)]
        [DscResourceProperty[]]
        $Parameters
    )
    
    $HashTable = New-Object -TypeName System.Text.StringBuilder

    Add-StringBuilderLine $HashTable "`t<#"
    Add-StringBuilderLine $HashTable "`t`$returnValue = @{"
    
    $Parameters | foreach {

        $HashTableEntry = New-Object -TypeName System.Text.StringBuilder
        Add-StringBuilderLine $HashTableEntry "`t`t" -Append
        Add-StringBuilderLine $HashTableEntry $_.Name -Append
        Add-StringBuilderLine $HashTableEntry " = [" -Append
        Add-StringBuilderLine $HashTableEntry $TypeMap[$_.Type].ToString() -Append
        Add-StringBuilderLine $HashTableEntry "]" -Append

        Add-StringBuilderLine $HashTable $HashTableEntry.ToString()

    }
    
    Add-StringBuilderLine $HashTable "`t}"
    Add-StringBuilderLine $HashTable
    Add-StringBuilderLine $HashTable "`t`$returnValue"
    Add-StringBuilderLine $HashTable "`t#>" -Append

    return $HashTable.ToString()
}

# Wrapper for StringBuilder.AppendLine that captures the returned StringBuilder object
function Add-StringBuilderLine 
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Text.StringBuilder]
        $Builder,

        [parameter(
            Mandatory = $false,
            Position = 2)]
        [System.String]
        $Line,

        [parameter(Mandatory = $false)]
        [Switch]
        $Append
    )
    
    if ($Append)
    {
        $null = $Builder.Append($Line)
        return     
    }
   

    if ($Line)
    {
        $null = $Builder.AppendLine($Line)
    }
    else
    {
        $null = $Builder.AppendLine()
    }
}

# Returns a hashTable mapping "functionName" to (functionStartLine, ParamBlockEndLine, functionEndLine)
function Get-FunctionParamLineNumbers
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $modulePath,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.String[]]
        $functionNames
    )

    $functionLineNumbers = @{}
    
    $contentString = [System.String]::Join([System.Environment]::NewLine, (Get-Content $modulePath))

    $parserErrors = @()

    #WARNING: ParseFile crashes on relative paths, use Get-Content + ParseInput instead
    $AST = [System.Management.Automation.Language.Parser]::ParseInput($contentString,[ref]$null,[ref]$parserErrors)

    #If there was a parsing error, report the errors and exit
    if ($parserErrors.Count -gt 0)
    {
        # Because we used ParseInput, we need to add the file name to the error message ourselves.

        $errorId = "ModuleParsingError"
        $errorMessage = $localizedData[$errorId] -f $modulePath

        for ($i = 0; $i -lt $parserErrors.Count - 1; $i++)
        {
            Write-Error ($errorMessage + " " + $parserErrors[$i].ToString().Replace("At line:", "at line:")) -ErrorId $errorId
        }
        Write-Error ($errorMessage + " " + $parserErrors[$i].ToString().Replace("At line:", "at line:")) -ErrorId $errorId -ErrorAction Stop
    }

    $AST.FindAll({$args[0].GetType().Equals([System.Management.Automation.Language.FunctionDefinitionAst])},$false) | foreach {
        
        if ($functionNames.Contains($_.Name))
        {
            $name = $_.Name

            $functionLineNumbers.Add($name, @())
            $functionLineNumbers[$name] += $_.Extent.StartLineNumber
            
            #Check for a ParamBlock
            if ($_.Body.ParamBlock.Extent.EndLineNumber)
            {
                $functionLineNumbers[$name] += $_.Body.ParamBlock.Extent.EndLineNumber
            }
            else
            {   #If there is no param block, 
                # The function's content starts the line after the "{"
                $functionLineNumbers[$name] += $_.Body.Extent.StartLineNumber + 1
            }

            
            $functionLineNumbers[$name] += $_.Extent.EndLineNumber
        }
    }

    return $functionLineNumbers
}

function Get-ContentFromFunctions
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $modulePath,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.Collections.Hashtable]
        $functionLineNumbers
    )

    $functionContent = @{}
    
    $moduleLines = Get-Content $modulePath
    

    foreach ($function in $functionLineNumbers.Keys)
    {
        $content = New-Object -TypeName System.Text.StringBuilder

        #Line immediately after end of param block
        $cur = (Convert-LineNumberToIndex $functionLineNumbers[$function][1]) + 1

        for (; $cur -lt (Convert-LineNumberToIndex $functionLineNumbers[$function][2]); $cur++)
        {
            $content.AppendLine($moduleLines[$cur]) | Out-Null
        }

        $functionContent.Add($function,$content.ToString())
    }

    return $functionContent
}

function Update-DscModule
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $ModulePath,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourceProperty[]]
        $Parameters,

        [Switch]
        $Force,
        
        [System.Management.Automation.PSCmdlet]
        $ParentPSCmdlet = $PSCmdlet
    )

    $functionNames = "Get-TargetResource","Set-TargetResource","Test-TargetResource"

    $functionLineNumbers = Get-FunctionParamLineNumbers $ModulePath $functionNames

    $functionContent = Get-ContentFromFunctions $ModulePath $functionLineNumbers


    $updatedFunctions = @{}

    # Create a function Get-TargetResource
    #   Add all parameters with the Key or Required tags
    $functionName = "Get-TargetResource"
    $updatedFunctions.Add($functionName, `
        (New-GetTargetResourceFunction $Parameters -FunctionContent $functionContent[$functionName]))
    
    
    # Create a function Set-TargetResource
    #    Add all parametes without the Read tag
    $functionName = "Set-TargetResource"
    $updatedFunctions.Add($functionName, `
        (New-SetTargetResourceFunction $Parameters -FunctionContent $functionContent[$functionName]))
    
    # Create a function Test-TargetResource
    #    Add all parametes without the Read tag
    $functionName = "Test-TargetResource"
    $updatedFunctions.Add($functionName, `
        (New-TestTargetResourceFunction $Parameters -FunctionContent $functionContent[$functionName]))


    
    $sortedFunctionList = Get-SortedFunctionNames $functionLineNumbers

    $moduleLines = Get-Content $ModulePath

    $newModule = New-Object -TypeName System.Text.StringBuilder
    


    #Start at the first line of the file
    $cur = 0

    foreach ($functionName in $sortedFunctionList)
    {
        #Copy from current index until start of next function
        for (; $cur -lt (Convert-LineNumberToIndex $functionLineNumbers[$functionName][0]); $cur++)
        {
            $newModule.AppendLine($moduleLines[$cur]) | Out-Null
        }

        $newModule.AppendLine($updatedFunctions[$functionName]) | Out-Null

        #Set cur to the line after the end of the function block
        $cur = (Convert-LineNumberToIndex $functionLineNumbers[$functionName][2]) + 1

    }

    # Copy everything after the end of the last function
    for (; $cur -lt $moduleLines.Count; $cur++)
    {
        $newModule.AppendLine($moduleLines[$cur]) | Out-Null
    }

    # Add any functions that weren't found in the module at the end of the file
    foreach ($functionName in $functionNames)
    {
        if (-not $sortedFunctionList.Contains($functionName))
        {
            $newModule.AppendLine() | Out-Null
            $newModule.AppendLine($updatedFunctions[$functionName]) | Out-Null
            $newModule.AppendLine() | Out-Null
        }
    }

    if ($Force -or $ParentPSCmdlet.ShouldProcess($ModulePath, $localizedData.OverWriteModuleOperation))
    {
        $newModule.ToString() | Out-File -FilePath $ModulePath -Force -Confirm:$false
    }
    else
    {
        Write-Warning ($localizedData.ModuleNotOverWrittenWarning -f $ModulePath)
    }
}

<#
.SYNOPSIS 
Update an existing DscResource based on the given arguments.

.DESCRIPTION
Update the .psm1 and .schema.mof file representing a Dsc Resource based on the property and values passed in.

.PARAMETER ModuleName
Either the name of module that Get-Module can find, or the path to folder containing the .psm1 and .schema.mof files.

.PARAMETER Property
Specifies the properties of the resource.

.PARAMETER ClassVersion
Optional, Specifies the version number of the resource.

.PARAMETER FriendlyName
Optional, Specifies the friendly name of the resource. Defaults to the same as the name.

.PARAMETER Force
Optional, determines if the cmdlet overwrites files without prompting.

.EXAMPLE
C:\PS> Update-xDscResource -ResourceDirectory "UserResource" -Property $UserName,$Ensure,$Password -ClassVersion 1.0 -FriendlyName "User" -Force
#>
function Update-xDscResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [Alias("Path")]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true)]
        [DscResourceProperty[]]
        $Property,

        [System.Version]
        $ClassVersion = "1.0.0.0",

        [System.String]
        $NewName,

        [Switch]
        $Force
    )
    
    
    $null = Test-AdministratorPrivileges
    # Will hold path to the .schema.mof file
    $Schema = "" 
    # Will hold path to the .psm1 file
    $Module = ""

    #Ignore the schema because we will be generating a new one regardless
    if (-not (Test-ResourcePath $Name ([ref]$Schema) ([ref]$Module) -IgnoreSchema))
    {
        return $false
    }

    $null = Test-PropertiesForResource $Property 
    
    $Name = [IO.Path]::GetFileNameWithoutExtension($Name)

    # The path to the folder containing the schema/module files
    $fullPath = [IO.Path]::GetDirectoryName($Schema)

    Update-DscModule $Module $Property -Force:$Force -ParentPSCmdlet $PSCmdlet -Confirm

    # Update the schema if Update-DscModule doesn't throw any errors.
    New-DscSchema $Name $fullPath $Property $ClassVersion -FriendlyName:$FriendlyName  -Force:$Force -ParentPSCmdlet $PSCmdlet -Confirm


    if (Test-xDscResource $fullPath)
    {
        Write-Verbose $localizedData["NewResourceSuccessVerbose"]
    }
    
}

#Line Numbers start at 1
# Indices start at 0
# Use this for readability
function Convert-LineNumberToIndex
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [int]
        $lineNumber
    )
    return $lineNumber - 1
}

#Sort the returned hashtable from Get-FunctionParamLineNumbers
# by the first number in the array
function Get-SortedFunctionNames
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Collections.Hashtable]
        $functionLineNumbers
    )
    
    # Sort based on the starting line number of the function
    return ($functionLineNumbers.Keys | Sort-Object {$functionLineNumbers[$_][0]})
}

#Check that ModuleName is either the path
# to a directory containing a psm1 and schema.mof file
#Or its the name of a module that Get-Module can find
function Test-ResourcePath
{
    [OutputType([Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0)]
        [System.String]
        $ModuleName,

        [parameter(
            Mandatory = $true,
            Position = 1)]
        [ref]
        $SchemaRef,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [ref]
        $ResourceModuleRef,

        [Switch]
        $IgnoreSchema
    )

    $Schema = ""
    $ResourceModule = ""

    $error = $false

    if (Test-Path -PathType Container $ModuleName)
    {    
        $fileName = [IO.Path]::GetFileNameWithoutExtension($ModuleName)

        $Schema = Join-Path $ModuleName ($fileName + ".schema.mof")
        $ResourceModule = Join-Path $ModuleName ($fileName + ".psm1")
    }
    else # We assume its the name of a module in $env:PSModulePath
    {
        $module = Get-DsCResource -Name $ModuleName

        if (-not $module)
        {
           Write-Error ($localizedData["ModuleNameNotFoundError"] -f $ModuleName) `
            -ErrorId "ModuleNotFoundError" -ErrorAction Stop 
        }

        $moduleFolder = [IO.Path]::GetDirectoryName($module.Path)
        $leaf = Split-Path $moduleFolder -Leaf

        $Schema = Join-Path $moduleFolder ($leaf + ".schema.mof")
        $ResourceModule = Join-Path $moduleFolder ($leaf + ".psm1")
    }

    if (-not $IgnoreSchema -and -not (Test-Path -PathType Leaf $Schema))
    {
        Write-Error ($localizedData["SchemaNotFoundInDirectoryError"] -f $Schema) `
            -ErrorId "SchemaNotFoundInDirectoryError" -ErrorAction Continue
        $error = $true
    }
    
    if (-not (Test-Path -PathType Leaf $ResourceModule))
    {
        Write-Error ($localizedData["ModuleNotFoundInDirectoryError"] -f $ResourceModule) `
            -ErrorId "ModuleNotFoundInDirectoryError" -ErrorAction Continue
        $error = $true
    }

    # If we couldn't load the schema and module
    if ($error)
    {
        return $false
    }
    
    #Otherwise return the path to the files
    $SchemaRef.Value = $Schema
    $ResourceModuleRef.Value = $ResourceModule

    return $true
    
}

<#
.SYNOPSIS 
Determines if the given resource will work with the Dsc Engine.

.DESCRIPTION
Finds and reports all errors in a given resource.

.PARAMETER ResourceModule
Either, a path to a directory containing a .psm1 and .schema.mof file,
or the name of a module that includes a .psm1 and .schema.mof file. 

.OUTPUTS
System.Boolean. True if no errors were found, false otherwise.

.EXAMPLE
C:\PS> Test-xDscResource "MSFT_UserResource"
True
#>
function Test-xDscResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName=$True)]
        [System.String]
        $Name
    )
    
    
    $null = Test-AdministratorPrivileges
    # Will hold path to the .schema.mof file
    $Schema = ""
    # Will hold path to the .psm1 file
    $ResourceModule = ""

    
    if (-not (Test-ResourcePath $Name ([ref]$Schema) ([ref]$ResourceModule)))
    {
        return $false
    }


    # SchemaCimClass and *CommandInfo are being used as [ref] objects
    #    as such they need to be initialized before they can be dereferenced
    # They have been assigned to 0, but will point to a CimClass object or
    #    CommandInfo objects respectively.

    $SchemaCimClass = 0

    $GetCommandInfo = 0
    $SetCommandInfo = 0
    $TestCommandInfo = 0

    Write-Verbose $localizedData["TestResourceTestSchemaVerbose"]
    $SchemaError = -not (Test-xDscSchemaInternal $Schema ([ref]$SchemaCimClass)) 

    Write-Verbose $localizedData["TestResourceTestModuleVerbose"]
    $ModuleError = -not (Test-DscResourceModule $ResourceModule ([ref]$GetCommandInfo) ([ref]$SetCommandInfo) ([ref]$TestCommandInfo)) 

    if ($SchemaError -or $ModuleError)
    {
        return $false
    }
    Write-Verbose $localizedData["TestResourceIndividualSuccessVerbose"]

    # Check the dependencies between the files



    $DscResourceProperties = Convert-SchemaToResourceProperty $SchemaCimClass 


    #Check get has all key and required and that they are mandatory

    $getMandatoryError = -not (Test-GetKeyRequiredMandatory $GetCommandInfo.Parameters `
                        ($DscResourceProperties | Where-Object {([DscResourcePropertyAttribute]::Key -eq $_.Attribute) `
                                    -or ([DscResourcePropertyAttribute]::Required -eq $_.Attribute)}))
    Write-Verbose ($localizedData["TestResourceGetMandatoryVerbose"] -f (-not $getMandatoryError))
    #Check that set has all write

    $setNoReadsError = -not (Test-SetHasExactlyAllNonReadProperties $SetCommandInfo.Parameters `
                    ($DscResourceProperties | Where-Object {([DscResourcePropertyAttribute]::Read -ne $_.Attribute)}))
    Write-Verbose ($localizedData["TestResourceSetNoReadsVerbose"] -f (-not $setNoReadsError))

    $getNoReadsError = -not (Test-FunctionTakesNoReads $GetCommandInfo.Parameters `
                    ($DscResourceProperties | Where-Object {([DscResourcePropertyAttribute]::Read -eq $_.Attribute)}) `
                    -Get)
    Write-Verbose ($localizedData["TestResourceGetNoReadsVerbose"] -f (-not $getNoReadsError))

    #The Test-TargetResource case is handled by SetHasExactlyAllNonReadProperties

    return -not ($getMandatoryError -or $setNoReadsError -or $getNoReadsError)
}

function Test-GetKeyRequiredMandatory
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.ParameterMetadata]]
        $GetParameters,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourceProperty[]]
        $KeyRequiredDscResourceProperties,

        [ref]
        $errorIdsRef
    )

    $errorIds = @()

    foreach ($property in $KeyRequiredDscResourceProperties)
    {

        if (-not $GetParameters[$property.Name] -or `
                -not (Test-ParameterMetaDataIsDscResourceProperty $GetParameters[$property.Name] $property))
        {
            $errorId = "GetMissingKeyOrRequiredError"
            Write-Error ($localizedData[$errorId] -f $property.Name) `
                -ErrorId $errorId -ErrorAction Continue 

            $errorIds += $errorId
        }
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }
    return ($errorIds.Length -eq 0)
}

function Test-SetHasExactlyAllNonReadProperties
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.ParameterMetadata]]
        $SetParameters,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourceProperty[]]
        $NonReadDscResourceProperties,

        [ref]
        $errorIdsRef
    )

    $propertiesHash = @{}

    $errorIds = @()

    #Make sure each NonRead Property is represented in the function
    foreach ($property in $NonReadDscResourceProperties)
    {
        
        if (-not $SetParameters[$property.Name] -or `
                -not (Test-ParameterMetaDataIsDscResourceProperty $SetParameters[$property.Name] $property))
        {
            $errorId = "SetAndTestMissingParameterError"
            Write-Error ($localizedData[$errorId] -f $property.Name) `
                -ErrorId $errorId -ErrorAction Continue 

            $errorIds += $errorId
        }

        $propertiesHash.Add($property.Name,$true)
    }
       
    #Make sure there are no extra properties in the function
    foreach ($parameter in $SetParameters.Values)
    {
        if (-not $propertiesHash[$parameter.Name] -and -not $commonParameters.Contains($parameter.Name))
        {
            $errorId = "SetAndTestExtraParameterError"
            Write-Error ($localizedData[$errorId] -f $parameter.Name) `
                -ErrorId $errorId -ErrorAction Continue 

            $errorIds += $errorId
        }
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }
    return ($errorIds.Length -eq 0)
}

function Test-FunctionTakesNoReads
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.ParameterMetadata]]
        $FunctionParameters,

        [parameter(
            Mandatory = $false,
            Position = 2)]
        [DscResourceProperty[]]
        $ReadDscResourceProperties,

        [Switch]
        $Get,

        [ref]
        $errorIdsRef
    )

    $errorIds = @()

    foreach ($property in $ReadDscResourceProperties)
    {
        if ($FunctionParameters[$property.Name])
        {
            $errorId = ""

            if ($Get)
            {
                $errorId = "GetTakesReadError"
                Write-Error ($localizedData[$errorId] -f $property.Name) `
                    -ErrorId $errorId -ErrorAction Continue 
            }
            else
            {
                $errorId = "SetTestTakeReadError"
                Write-Error ($localizedData[$errorId] -f $property.Name) `
                    -ErrorId $errorId -ErrorAction Continue 
            }   

            $errorIds += $errorId
        }
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }
    return ($errorIds.Length -eq 0)
}

#Given parameterMetaData from a function, and a DscResourceProperty
# returns true, if the parameter could be an instance of this property
function Test-ParameterMetaDataIsDscResourceProperty
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.ParameterMetadata]
        $parameter,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [DscResourceProperty]
        $property
    )


    # Because the arguments selected based on having the same name property
    # This shouldn't happen...
    if ($parameter.Name -ne $property.Name)
    {
        return $false
    }

    if ($property.Attribute -eq "Read")
    {
        $errorId = "SchemaModuleReadError"
        Write-Error ($localizedData[$errorId] -f $property.Name) `
            -ErrorId $errorId -ErrorAction Continue 
        if($errorIdRef)
        {
            $errorIdRef.Value = $errorId
        }
        return $false
    }

    if (($property.Attribute -eq "Key" -or $property.Attribute -eq "Required") -xor (Test-ParameterIsMandatory $parameter))
    {
        $errorId = "SchemaModuleAttributeError"
        Write-Error ($localizedData[$errorId] -f $property.Name) `
            -ErrorId $errorId -ErrorAction Continue 
        if($errorIdRef)
        {
            $errorIdRef.Value = $errorId
        }
        return $false
    }

    if ($TypeMap[$property.Type].FullName -ne $parameter.ParameterType.FullName)
    {
        $errorId = "SchemaModuleTypeError"
        Write-Error ($localizedData[$errorId] -f $property.Name) `
            -ErrorId $errorId -ErrorAction Continue 
        if($errorIdRef)
        {
            $errorIdRef.Value = $errorId
        }
        return $false
    }

    $parameterValidateSet = Get-ValidateSet $parameter

    if ($property.ValidateSet -xor $parameterValidateSet)
    {
        $errorId = "SchemaModuleValidateSetDiscrepancyError"
        Write-Error ($localizedData[$errorId] -f $property.Name) `
            -ErrorId $errorId -ErrorAction Continue 
        if($errorIdRef)
        {
            $errorIdRef.Value = $errorId
        }
        return $false
    }
    elseif (-not $property.ValidateSet -and -not $parameterValidateSet)
    {
        # both are null
        return $true
    }
    else
    {
        #compare the two lists

        if ($property.ValidateSet.Count -ne $parameterValidateSet.Count)
        {
            $errorId = "SchemaModuleValidateSetCountError"
            Write-Error ($localizedData[$errorId] -f $property.Name) `
                -ErrorId $errorId -ErrorAction Continue 
            if($errorIdRef)
            {
                $errorIdRef.Value = $errorId
            }
            return $false
        }
        
        foreach ($item in $property.ValidateSet)
        {
            if (-not $parameterValidateSet.Contains($item))
            {
                $errorId = "SchemaModuleValidateSetItemError"
                Write-Error ($localizedData[$errorId] -f $property.Name,$item.ToString()) `
                    -ErrorId $errorId -ErrorAction Continue 
                if($errorIdRef)
                {
                    $errorIdRef.Value = $errorId
                }
                return $false
            }
        }

        return $true
    }

    return $true
}

# Given a property from a schema file, make sure everything inside it is allowed in a Dsc Schema
function Test-SchemaProperty
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [Microsoft.Management.Infrastructure.CimPropertyDeclaration]
        $CimProperty,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [ref]
        $HasKeyRef,

        [parameter(
            Mandatory = $true,
            Position = 3)]
        [ref]
        $ErrorIdsRef
    )

    # Pass back that this property was marked as Key
    if ($cimProperty.Qualifiers["Key"])
    {
        $HasKeyRef.Value = $true
    }

    if (-not ($cimProperty.Qualifiers["Key"] -or $CimProperty.Qualifiers["Required"] `
             -or $CimProperty.Qualifiers["Write"] -or $CimProperty.Qualifiers["Read"]))
    {
        $errorId = "MissingAttributeError"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value += $errorId
    }
    elseif ($CimProperty.Qualifiers["Read"] -and ($cimProperty.Qualifiers["Key"] -or $CimProperty.Qualifiers["Required"] `
             -or $CimProperty.Qualifiers["Write"]))
    {
        $errorId = "IllegalAttributeCombinationError"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value += $errorId
    }
    elseif ($CimProperty.Qualifiers["Key"] -and $CimProperty.Qualifiers["EmbeddedInstance"])
    {
        $errorId = "IllegalAttributeCombinationError"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value += $errorId
    }


    # Check if this property has a valid Type

    $simplifiedType = $CimProperty.CimType.ToString()

    $isArray = $CimProperty.CimType.ToString() -cmatch "^(.*)Array$"

    if ($isArray)
    {
        $simplifiedType = $Matches[1]+"[]"
    }

    if (-not $TypeMap.ContainsKey($simplifiedType))
    {
        $errorId = "UnsupportedMofTypeError"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name,$CimProperty.CimType.ToString()) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value +=  $errorId 
    }


    if ($CimProperty.Qualifiers["ValueMap"] -or $CimProperty.Qualifiers["Values"])
    {
        $ValueMap = $CimProperty.Qualifiers["ValueMap"].Value
        $Values = $CimProperty.Qualifiers["Values"].Value

        $error = $false

        # Make sure if either of ValueMap or Values are present, both are.
        if ((-not ($ValueMap -and $Values)) `
            -or ($ValueMap.Count -ne $Values.Count))
        {
            $error = $true
        }
        else
        {
            for ($i = 0; $i -lt $ValueMap.Count; $i++)
            {
                # Make sure the values contained in ValueMap and Values are identical
                if ($ValueMap[$i] -ne $Values[$i])
                {
                    $error = $true
                    break
                }
            }
        }
        
        if ($error)
        {
            $errorId = "ValueMapValuesPairError"
            Write-Error ($localizedData[$errorId] -f ($CimProperty.Name)) `
                -ErrorId $errorId -ErrorAction Continue
            $ErrorIdsRef.Value +=  $errorId 
        }
    }

    if ($CimProperty.Qualifiers["EmbeddedInstance"] `
            -and ($CimProperty.Qualifiers["EmbeddedInstance"].Value -ne "MSFT_Credential") `
            -and ($CimProperty.Qualifiers["EmbeddedInstance"].Value -ne "MSFT_KeyValuePair"))
    {
        $errorId = "InvalidEmbeddedInstance"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name,$CimProperty.Qualifiers["EmbeddedInstance"].Value) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value += $errorId
    }

    if ($CimProperty.Qualifiers["EmbeddedInstance"] `
            -and (($CimProperty.Qualifiers["EmbeddedInstance"].Value -eq "MSFT_Credential") `
                -or ($CimProperty.Qualifiers["EmbeddedInstance"].Value -eq "MSFT_KeyValuePair")) `
            -and (($CimProperty.CimType -ne "String") -and ($CimProperty.CimType -ne "StringArray")))
    {
        $errorId = "EmbeddedInstanceCimTypeError"
        Write-Error ($localizedData[$errorId] -f $CimProperty.Name) `
            -ErrorId $errorId -ErrorAction Continue
        $ErrorIdsRef.Value += $errorId
    }
}

# Given a Schema.Mof file, it creates an identical copy but removes the ": OMI_BaseResource" reference
# Then uses mofcomp to upload the schema, sets $SchemaCimClass, and removes the WMI_Object and temp schema
# Possible errors it will return : MissingOMI_BaseResource,ClassNameSchemaNameDifferent, and any mofcomp/Get-CimClass error
function Test-MockSchema
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Schema,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [ref]
        $SchemaCimClass,

        [ref]
        $errorIdsRef
    )

    # Returns full path to a 0 byte .tmp file
    $tempFilePath = [IO.Path]::GetTempFileName() 

    $tempFolderPath = [IO.Path]::GetDirectoryName($tempFilePath)

    # Extracts the ????.tmp name
    $newSchemaName = [IO.Path]::GetFileNameWithoutExtension($tempFilePath)

    # We can now use the temp file name to create a new unique file
    Remove-Item $tempFilePath

    $newSchemaPath = "$tempFolderPath\$newSchemaName.schema.mof"

    $null = New-Item $newSchemaPath -ItemType File

    $null = [IO.Path]::GetFileNameWithoutExtension($Schema) -cmatch "(.+)\.schema"
    $schemaName = $Matches[1]

    # Initialize this to correct; it will be overwritten if incorrect
    $className = $schemaName

    $extendsOMI = $false

    Get-Content $Schema | % {
        $newLine = $_
    
        # Match to grab class name without grabbing ": OMI_BaseResource"
        # \w - is the current regex for class names
        if ($_ -cmatch "^class\s+([\w-&\(\)\[\]]+)\s*:?")
        {
            $className = $Matches[1]
        }

        if ($_ -cmatch "^class\s+$className\s*:\s*OMI_BaseResource")
        {
            $extendsOMI = $true
            $newLine = $_ -replace $Matches[0],"class $newSchemaName"
        }

        Add-Content $newSchemaPath $newLine
    }

    if (-not $extendsOMI -or ($schemaName -ne $className))
    {
        $errorIds = @()

        if (-not $extendsOMI)
        {
            $errorId = "MissingOMI_BaseResourceError"
            $errorIds += $errorId
            Write-Error ($localizedData[$errorId] -f $schemaName) `
                        -ErrorId $errorId -ErrorAction Continue
        }

        if ($schemaName -ne $className)
        {
            $errorId = "ClassNameSchemaNameDifferentError"
            $errorIds += $errorId
            Write-Error ($localizedData[$errorId] -f $className,$schemaName) `
                        -ErrorId $errorId -ErrorAction Continue
        }

        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return ($errorIds.Length -eq 0)
    }
    
    $parseResult = mofcomp.exe -N:root\microsoft\windows\DesiredStateConfiguration -class:forceupdate $newSchemaPath
    
    # This shouldn't happen because mofcomp.exe -check is run previously
    if ($LASTEXITCODE -ne 0)
    {
        $errorIds = @()
        $errorId = "SchemaParseError"
        

        $parseText = New-Object -TypeName System.Text.StringBuilder
        
        $parseResult | % {
            Add-StringBuilderLine $parseText $_
        }

        Write-Error ($parseText.ToString()) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
        
        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return ($errorIds.Length -eq 0)
    }


    $SchemaCimClass.Value = Get-CimClass -Namespace root\microsoft\windows\DesiredStateConfiguration -ClassName $newSchemaName -ErrorAction Continue -ErrorVariable ev

    if ($ev)
    {
        $errorIds = @()
        $errorId = "GetCimClass-Error"
       
        # Let Get-CimClass display its error, then report the error 

        Write-Error ($localizedData[$errorId] -f $schemaName) `
           -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId

        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return ($errorIds.Length -eq 0)
    }

    $hasKey = $false
    
    $errorIds = @()

    $SchemaCimClass.Value.CimClassProperties | % {

        $null = Test-SchemaProperty $_ ([ref]$hasKey) ([ref]$errorIds)

    }
    
    if (-not $hasKey)
    {
        $errorId = "NoKeyTestError"
        Write-Error ($localizedData[$errorId]) `
            -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId 
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }
    return ($errorIds.Length -eq 0)

    try{}
    catch{}
    finally{
       Remove-WmiObject -Class $newSchemaName -Namespace root\microsoft\windows\DesiredStateConfiguration -ErrorAction SilentlyContinue
       Remove-Item $newSchemaPath -ErrorAction SilentlyContinue
    }   
}

# Given the path to a Schema.Mof file, check to see if has the BOM for UTF8
# If so, give the option to re-encode it for them or throw error
# Otherwise, return true
function Test-xDscSchemaEncoding
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Schema
    )

    $schemaBytes = Get-Content -Encoding Byte $Schema

    # These are the UTF8 Byte Order Marks as read by PowerShell's Get-Content -Encoding Byte
    # [System.Text.Encoding]::UTF8.GetPreamble()
    if (($schemaBytes.Length -ge 3) `
        -and ($schemaBytes[0] -eq 239) `
        -and ($schemaBytes[1] -eq 187) `
        -and ($schemaBytes[2] -eq 191))
    {
        #Prompt the user to re-encode their schema as Unicode...
        if ($pscmdlet.ShouldProcess($Schema, $localizedData["SchemaEncodingNotSupportedPrompt"]))
        {
            Write-Verbose $localizedData["SchemaFileReEncodingVerbose"]

            $schemaContent = Get-Content $Schema 
            $schemaContent | Out-File -Encoding unicode $Schema -Force
        }
        #Otherwise fail
        else
        {
            Write-Error $localizedData["SchemaEncodingNotSupportedError"] -ErrorAction Continue
            return $false
        }
    }

    return $true
}

function Test-xDscSchema
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeLineByPropertyName = $true)]
        [System.String]
        $Path,

        [Switch]
        $IncludeError
    )

    if($IncludeError)
    {
        $Errors = 0
        Test-xDscSchemaInternal -Schema $Path -errorIdsRef [ref]$Errors
    }
    else
    {
        Test-xDscSchemaInternal -Schema $Path
    }
}

# Tests a given schema file to make sure it passes all contracts required by Dsc.
function Test-xDscSchemaInternal
{
    [OutputType([Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true)]
        [System.String]
        $Schema,

        [parameter(
            Mandatory = $false,
            Position = 2)]
        [ref]
        $SchemaCimClass,

        [ref]
        $errorIdsRef
    )

    $ev = $null
    $goodPath = Test-Path $Schema -PathType Leaf -ErrorVariable $ev -ErrorAction Continue

    if ($ev -or -not $goodPath  -or -not($Schema -cmatch ".*\.schema\.mof$"))
    {
        $errorId = "BadSchemaPath"
        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        
        if ($errorIdsRef)
        {
            $errorIdsRef.Value = @()
            $errorIdsRef.Value += $errorId
        }
        
        return $false
    }
    Write-Verbose ($localizedData["SchemaPathValidVerbose"])

    if (-not (Test-xDscSchemaEncoding $Schema))
    {
        return $false;
    }

    $filename = [IO.Path]::GetFileName($Schema)
    $null = $filename -cmatch "^(.*)\.schema\.mof$"
    $SchemaName = $Matches[1] 

    $parseResult = mofcomp.exe -Check $Schema
     
    if ($LASTEXITCODE -ne 0)
    {
        $errorIds = @()
        $errorId = "SchemaParseError"

        $parseText = New-Object -TypeName System.Text.StringBuilder
        
        $parseResult | % {
            Add-StringBuilderLine $parseText $_
        }

        Write-Error ($parseText.ToString()) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
        #Write-Error ($localizedData[$errorId]) `
        #                -ErrorId $errorId -ErrorAction Continue
        # To check for this error, use $Error
        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return $false
    }
 
    Write-Verbose ($localizedData["SchemaMofCompCheckVerbose"])

    # If used just to test the schema, they don't need the cimClass
    if (-not $SchemaCimClass)
    {
        $temp = 0
        $SchemaCimClass = ([ref]$temp)
    }

    Write-Verbose ($localizedData["SchemaDscContractsVerbose"])
    if ($errorIdsRef)
    {
            return (Test-MockSchema $Schema $SchemaCimClass -errorIdsRef $errorIdsRef)
    }
    else
    {
            return (Test-MockSchema $Schema $SchemaCimClass)
    }

}

function Test-DscResourceModule
{
    [OutputType([Boolean])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Module,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [ref]
        $GetCommandInfo,

        [parameter(
            Mandatory = $true,
            Position = 3)]
        [ref]
        $SetCommandInfo,

        [parameter(
            Mandatory = $true,
            Position = 4)]
        [ref]
        $TestCommandInfo,

        [ref]
        $errorIdsRef
    )

    $ev = $null
    $goodPath = Test-Path $Module -PathType Leaf -ErrorVariable ev -ErrorAction Continue

    if ($ev -or -not $goodPath -or ([IO.Path]::GetExtension($Module) -ne ".psm1" -and [IO.Path]::GetExtension($Module) -ne ".dll"))
    {
        $errorIds = @()
        $errorId = "BadResourceModulePath"

        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId 

        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return $false
    }

    $ModuleName = [IO.Path]::GetFileNameWithoutExtension($Module)

    $Prefix = [IO.Path]::GetRandomFileName()

    $ev = $null
    
    Import-Module $Module -Prefix $Prefix -Force -NoClobber -ErrorVariable ev -ErrorAction Continue

    if ($ev)
    {
        $errorIds = @()
        $errorId = "ImportResourceModuleError"
        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId

        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return $false
    }

    
    
    $undefinedFunctions = @() 

    $ev = $null
    
    $GetCommandInfo.Value = Get-Command ("Get-" + $Prefix + "TargetResource") -Module $ModuleName -ErrorAction SilentlyContinue -ErrorVariable ev
    
    if ($GetCommandInfo.Value -eq $null -or $ev)
    {
        $undefinedFunctions += "Get-TargetResource"
    }

    $ev = $null
    
    $SetCommandInfo.Value = Get-Command ("Set-" + $Prefix + "TargetResource") -Module $ModuleName -ErrorAction SilentlyContinue -ErrorVariable ev
    
    if ($SetCommandInfo.Value -eq $null -or $ev)
    {
        $undefinedFunctions += "Set-TargetResource"
    }

    $ev = $null
    
    $TestCommandInfo.Value = Get-Command ("Test-" + $Prefix + "TargetResource") -Module $ModuleName -ErrorAction SilentlyContinue -ErrorVariable ev
    
    if ($TestCommandInfo.Value -eq $null -or $ev)
    {
        $undefinedFunctions += "Test-TargetResource"
    }

    if ($undefinedFunctions.Length -gt 0)
    {
        $errorIds = @()
        $errorId = "KeyFunctionsNotDefined"
        Write-Error ($localizedData[$errorId] -f (New-DelimitedList $undefinedFunctions -Separator ", ")) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId

        if ($errorIdsRef)
        {
            $errorIdsRef.Value = $errorIds
        }
        return $false
    }

    $errorIds = @()

    if (-not $GetCommandInfo.Value.OutputType)
    {
        Write-Warning $localizedData["GetTargetResourceOutWarning"]
    }
   
    if ($GetCommandInfo.Value.OutputType -and $GetCommandInfo.Value.OutputType.Type -ne [Hashtable])
    {
        $errorId = "GetTargetResourceOutError"
        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    #Set should not have an output type
    if ($SetCommandInfo.Value.OutputType)
    {
        $errorId = "SetTargetResourceOutError"
        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    if (-not $TestCommandInfo.Value.OutputType)
    {
        Write-Warning $localizedData["TestTargetResourceOutWarning"]
    }
    if ($TestCommandInfo.Value.OutputType -and $TestCommandInfo.Value.OutputType.Type -ne [Boolean])
    {
        $errorId = "TestTargetResourceOutError"
        Write-Error ($localizedData[$errorId]) `
                        -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    #Make sure each has at least one mandatory property that isnt an array
    # and that it only has parameters of valid types

    $getErrors = @()
    $setErrors = @()
    $testErrors = @()

    $null = Test-BasicDscFunction $GetCommandInfo.Value "Get-TargetResource" -errorIdsRef ([ref]$getErrors)
    $errorIds += $getErrors
    $null = Test-BasicDscFunction $SetCommandInfo.Value "Set-TargetResource" -errorIdsRef ([ref]$setErrors)
    $errorIds += $setErrors
    $null = Test-BasicDscFunction $TestCommandInfo.Value "Test-TargetResource" -errorIdsRef ([ref]$testErrors)
    $errorIds += $testErrors

    
    # Set == Test

    $setTestErrors = @()

    $null = Test-SetTestIdentical $SetCommandInfo.Value $TestCommandInfo.Value -errorIdsRef ([ref]$setTestErrors)
    $errorIds += $setTestErrors


    # Get is subset of Set/Test
    #  Only check this if Test-SetTestIdentical succeeds, so we only need to compare against Set
    if ($errorIds.Count -eq 0)
    {
        $getSubsetErrors = @()
        $null = Test-GetSubsetSet $GetCommandInfo.Value $SetCommandInfo.Value -errorIdsRef ([ref]$getSubsetErrors)
        $errorIds += $getSubsetErrors
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }

    return $errorIds.Count -eq 0

    try{}
    catch{}
    finally
    {
       Remove-Module $ModuleName -ErrorAction SilentlyContinue
    }
}

# Make sure that for every parameter in Get, Set contains that parameter.
# Because we also check Set-Test Identical, we get Get subset Test for free
function Test-GetSubsetSet
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.CommandInfo]
        $getCommandInfo,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.Management.Automation.CommandInfo]
        $setCommandInfo,

        [ref]
        $errorIdsRef
    )

    $errorIds = @()

    $commonParameterError = $false

    foreach ($parameter in $getCommandInfo.Parameters.Values)
    {
        
        if (-not $setCommandInfo.Parameters.Keys.Contains($parameter.Name))
        {
            
            if ($commonParameters.Contains($parameter.Name))
            {
                # Ignore Verbose,ErrorAction, etc
                # We can't report that Set doesnt contain $commonParameter X
                # because neither function actually "contains" it
                # It indicates an error elsewhere though
                # so we'll make sure an error is reported. 
                $commonParameterError = $true   
            }
            else
            {
                $errorId = "SetTestMissingGetParameterError"
                Write-Error ($localizedData[$errorId] -f $parameter.Name) `
                    -ErrorId $errorId -ErrorAction Continue
                $errorIds += $errorId
            }

            continue;
        }
        
        $identicalParametersErrors = @()

        $null = Test-ParametersAreIdentical `
                        $parameter "Get-TargetResource" `
                        $setCommandInfo.Parameters[$parameter.Name] "Set-TargetResource" `
                        -errorIdsRef ([ref]$identicalParametersErrors)
        
        $errorIds += $identicalParametersErrors
        
    }

    #Report the top level rule about all Get Parameters
    # being represented in Set and Tests
    if ($errorIds.Count -ne 0)
    {
        $errorId = "GetParametersDifferentError"
        Write-Error ($localizedData[$errorId]) `
                -ErrorId $errorId -ErrorAction Continue
            $errorIds += $errorId
    }

    if($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }

    return $errorIds.Length -eq 0
}

function Test-ParametersAreIdentical
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.ParameterMetadata]
        $parameterA,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [String]
        $functionA,

        [parameter(
            Mandatory = $true,
            Position = 3)]
        [System.Management.Automation.ParameterMetadata]
        $parameterB,

        [parameter(
            Mandatory = $true,
            Position = 4)]
        [String]
        $functionB,

        [ref]
        $errorIdsRef
    )
    
    $errorIds = @()
    
    if (-not (Test-ParametersValidateSet $parameterA $parameterB))
    {
        $errorId = "ModuleValidateSetError"
        Write-Error ($localizedData[$errorId] -f $parameterA.Name,$functionA,$functionB) `
                -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId

    }
        
    

    if ((Test-ParameterIsMandatory $parameterA) -xor (Test-ParameterIsMandatory $parameterB))
    {
        $errorId = "ModuleMandatoryError"
        Write-Error ($localizedData[$errorId] -f $parameterA.Name,$functionA,$functionB) `
                -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }
        
    if ($parameterA.ParameterType -ne $parameterB.ParameterType)
    {
        $errorId = "ModuleTypeError"
        Write-Error ($localizedData[$errorId] -f $parameterA.Name,$functionA,$functionB) `
                -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    if($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }

    return $errorIds.Length -eq 0
}

function Test-ParameterIsMandatory
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.ParameterMetadata]
        $parameter
    )

    foreach ($attribute in $parameter.Attributes)
    {
        if ($attribute.GetType() -eq [System.Management.Automation.ParameterAttribute])
        {
            return $attribute.Mandatory
        }
    }

    return $false
}

function Test-ParametersValidateSet
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.ParameterMetadata]
        $parameter1,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.Management.Automation.ParameterMetadata]
        $parameter2
    )

    
    $a = Get-ValidateSet $parameter1
    $b = Get-ValidateSet $parameter2

    
    if ((-not $a) -and (-not $b))
    {
        return $true
    }
    elseif ($a -and $b)
    {
        

        if ($a.Count -ne $b.Count)
        {
            return $false
        }

        foreach ($item in $a)
        {
            if (-not $b.Contains($item))
            {
                return $false
            }
        }

        return $true
    }

    return $false

}

function Get-ValidateSet
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.ParameterMetadata]
        $parameter
    )

    foreach ($attribute in $parameter.Attributes)
    {
        if ($attribute.GetType() -eq `
            [System.Management.Automation.ValidateSetAttribute])
        {
            return $attribute.ValidValues
        }
    }

    return $null
}

function Test-BasicDscFunction
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.CommandInfo]
        $command,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [String]
        $commandName,

        [parameter(
            Position = 3)]
        [ref]
        $errorIdsRef
    )

    $errorIds = @()

    # This would be a mandatory, non-array parameter 
    $hasValidKey = $false

    foreach ($parameter in $command.Parameters.Values)
    {
        if ($commonParameters.Contains($parameter.Name))
        {
            continue;
        }

        if (-not $TypeMap.ContainsValue($parameter.ParameterType))
        {
            $errorId = "UnsupportedTypeError"
            Write-Error ($localizedData[$errorId] -f `
                $commandName,$parameter.ParameterType,$parameter.Name) `
                -ErrorId $errorId -ErrorAction Continue
            $errorIds += $errorId
        }
        elseif ((Test-ParameterIsMandatory $parameter) `
                -and ($parameter.ParameterType.BaseType -ne [System.Array]))
        {
            $hasValidKey = $true
        }
    }

    if (-not $hasValidKey)
    {
        $errorId = "NoKeyPropertyError"
        Write-Error ($localizedData[$errorId] -f $commandName) `
            -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    if ($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }
    return $errorIds.Length -eq 0

}


# Makes sure two CommandInfo objects take the same parameters.
# Is generic upto the point where the function names are hardcoded.
# (Because the actual commandInfo objects belong to SET/Test-XXXXXTargetResource
function Test-SetTestIdentical
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.Management.Automation.CommandInfo]
        $setCommand,

        [parameter(
            Mandatory = $true,
            Position = 2)]
        [System.Management.Automation.CommandInfo]
        $testCommand,

        [ref]
        $errorIdsRef
    )

    $errorId = "NoError"
    

    if ($setCommand.Parameters.Count -eq 0 -and $testCommand.Parameters.Count -eq 0)
    {
        #This will already have been reported by Test-BasicDscFunction
        $errorId = "NoKeyPropertyError"
        
        if($errorIdsRef)
        {
            $errorIdsRef.Value = @()
            $errorIdsRef.Value += $errorId
        }
        

        return $false
    }
    
    #  We can assume that if somebody took time to write a parameter
    #   that is only in one function,
    #   than it is more likely that they forgot to add it to the other, 
    #   rather than that it was mistakenly included.
    # So check the function with more parameters first.

    # Determine which function has more parameters.

    $commandWithFewerParameters = $testCommand
    $commandWithMoreParameters = $setCommand
    $commandNameWithFewerParameters = "Test-TargetResource"
    $commandNameWithMoreParameters = "Set-TargetResource"

    if ($setCommand.Parameters.Values.Count -lt $testCommand.Parameters.Values.Count)
    {
        $commandWithFewerParameters = $setCommand
        $commandWithMoreParameters = $testCommand
        $commandNameWithFewerParameters = "Set-TargetResource"
        $commandNameWithMoreParameters = "Test-TargetResource"
    }

    $errorIds = @()
    $errorReported = $false

    # Loop over the longer list, if we find errors, report them then stop
    foreach($parameter in $commandWithMoreParameters.Parameters.Values)
    {

        # Powershell automatically adds common parameters to functions (Verbose/Debug/ErrorAction/etc)
        #   Displaying an error regarding these auto populated parameters is not useful

        if ($commonParameters.Contains($parameter.Name))
        {
            continue;
        }

        if (-not $commandWithFewerParameters.Parameters[$parameter.Name])
        {
            $errorId = "SetTestMissingParameterError"
            Write-Error ($localizedData[$errorId] -f $commandNameWithFewerParameters,$parameter.Name,$commandNameWithMoreParameters) `
                -ErrorId $errorId -ErrorAction Continue
            $errorIds += $errorId
            $errorReported = $true
            continue;
        }

        $newErrorIds = @()
        $null = Test-ParametersAreIdentical $parameter $commandNameWithMoreParameters $commandWithFewerParameters.Parameters[$parameter.Name] $commandNameWithFewerParameters -errorIdsRef ([ref]$newErrorIds)

        if ( $newErrorIds.Count -ne 0)
        {
            $errorIds += $newErrorIds
            $errorReported = $true
        }
    }

    
    if ($setCommand.Parameters.Values.Count -ne $testCommand.Parameters.Values.Count `
        -and -not $errorReported)
    {
        # if the counts are different but we didnt get an error, something is wrong...
        $errorId = "SetTestNotIdenticalError"
        Write-Error ($localizedData[$errorId]) `
            -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
        $errorReported = $true
    }
    elseif ($errorReported) # If there is an error, give the Set/Testerror as well
    {
        $errorId = "SetTestNotIdenticalError"
        Write-Error ($localizedData[$errorId]) `
            -ErrorId $errorId -ErrorAction Continue
        $errorIds += $errorId
    }

    
    if($errorIdsRef)
    {
        $errorIdsRef.Value = $errorIds
    }

    return $errorIds.Length -eq 0
}


# Throws an exception if New-DscResource or Test-DscResource are run without admin rights.
function Test-AdministratorPrivileges
{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        $errorId = "AdminRightsError"
        Write-Error $localizedData[$errorId] `
            -ErrorId $errorId -ErrorAction Stop
    }

    return $true
}
# Only run Convert-Cim* functions on a Schema that has been tested!

# Given a CimClass object, returns an array of DscResourceProperties
function Convert-SchemaToResourceProperty
{
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [Microsoft.Management.Infrastructure.CimClass]
        $CimClass
    )

    $properties = @()

    foreach ($cimProperty in $CimClass.CimClassProperties)
    {
        $properties += New-xDscResourceProperty `
                            -Name $cimProperty.Name `
                            -Type (Convert-CimType $cimProperty) `
                            -Attribute (Convert-CimAttribute $cimProperty) `
                            -ValidateSet $cimProperty.Qualifiers["Values"].Value `
                            -Description $CimProperty.Qualifiers["Description"].Value
    }

    return $properties
}

# Given a  CimPropertyDeclaration returns Key/Required/Write/Read
function Convert-CimAttribute
{
    param
    (
        [parameter(
            Mandatory = $true,
            position = 1)]
        [Microsoft.Management.Infrastructure.CimPropertyDeclaration]
        $CimProperty
    )

    if ($CimProperty.Qualifiers["Key"])
    {
        return "Key"
    }
    elseif ($CimProperty.Qualifiers["Required"])
    {
        return "Required"
    }
    elseif ($CimProperty.Qualifiers["Write"])
    {
        return "Write"
    }
    else
    {
        return "Read"
    }
}

# Given a CimPropertyDeclaration returns something from $TypeMap.Keys
function Convert-CimType
{
    param
    (
        [parameter(
            Mandatory = $true,
            position = 1)]
        [Microsoft.Management.Infrastructure.CimPropertyDeclaration]
        $CimProperty
    )

    if (-not $CimProperty.Qualifiers["EmbeddedInstance"])
    {
        if ($CimProperty.CimType.ToString() -cmatch "^(.+)Array$")
        {
            # If the Type ends with "Array", replace it with "[]"
            return ($Matches[1] + "[]")
        }
        else
        {
            return $CimProperty.CimType.ToString()
        }
    }

    $reverseEmbeddedInstance = @{
        "MSFT_KeyValuePair" = "Hashtable";
        "MSFT_Credential" = "PSCredential";
    }

    $arrayAddOn = ""

    if ($CimProperty.CimType.ToString().EndsWith("Array"))
    {
        $arrayAddOn = "[]"
    }

    return $reverseEmbeddedInstance[$CimProperty.Qualifiers["EmbeddedInstance"].Value]+$arrayAddOn

}

#Given a schema file, if the schema file passes Test-xDscSchema
# Returns a HashTable mapping "ResourceName" to Name,
# "FriendlyName" to FriendlyName, "ClassVersion" to ClassVersion,
# and "DscResourceProperties" to DscResourceProperties created from the properties
# found within the schema file.
function Import-xDscSchema
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(
            Mandatory = $true,
            Position = 1)]
        [System.String]
        $Schema
    )

    # Define variable to hold the CimClass
    # Passed by reference to Test-xDscSchema
    $cimClass = 0

    if (-not (Test-xDscSchemaInternal $Schema ([ref]$cimClass)))
    {
        #If the file does not pass Test-xDscSchema, return nothing.
        return
    }

    Write-Verbose ($localizedData["ImportTestSchemaVerbose"])

    #If the file passes Test-xDscSchema

    # This holds the name of the temp file -> $cimClass.CimClassName
    # Get the name from the original fileName.
    $fileName = [IO.Path]::GetFileName($Schema)
    $null = $fileName -cmatch "^(.*).schema.mof$"

    Write-Verbose ($localizedData["ImportReadingPropertiesVerbose"])

    $resourceName = $Matches[1];

    $friendlyName = ""
    if ($cimClass.CimClassQualifiers["FriendlyName"])
    {
        $friendlyName = $cimClass.CimClassQualifiers["FriendlyName"].Value.ToString();
    }

    $classVersion = ""
    if ($cimClass.CimClassQualifiers["ClassVersion"])
    {
        $classVersion = $cimClass.CimClassQualifiers["ClassVersion"].Value.ToString();
    }

    $properties = Convert-SchemaToResourceProperty $cimClass

    return @{
                "ResourceName"=$resourceName;
                "FriendlyName"=$friendlyName;
                "ClassVersion"=$classVersion;
                "DscResourceProperties"=$properties;
            }
}



