 <#
 
 edit for branch merger
.SYNOPSIS
Testupdate
  Runbook to deploy an ARM template
.DESCRIPTION
    This runbook takes input from either a parent runbook or directly to deploy an ARM template
    The runbook expects access to Azure file services for uploading a log file after operations are finished. 
.PARAMETER ResourceGroupName
    The name of the Resource Group to deploy the ARM template in
.PARAMETER ResourceGroupLocation
    The Azure region the resource group is in, must me in short form, e.g. westeurope, asiapacific, etc
.PARAMETER $AzureConnectionAccount
    Optional: Not required when this is called from a runbook which is already logged into Azure with the required credentials
    The name of the Azure connection asset used to connect to Azure
.PARAMETER TemplateUri
    Url to the ARM template, will typically be on github
.PARAMETER TemplateParameterFileName
    The file name of the ARM template file name, expected to be populated with correct values and placed in $fileworkingpath at this point
.PARAMETER ArmDeploymentName
    Name of the ARM deployment
.PARAMETER FileWorkingPath
    File storage path in short form, i.e. directory name, typically same as resource group name
.PARAMETER RepositoryResourceGroup
    Resource group for file services, logs and temporary files for ARM deployment
.PARAMETER RepositoryShareName
    File services share name for logs and temporary files for ARM deployment
.EXAMPLE
    New-ArmTemplateDeployment -ResourceGroupLocation westeurope `
    -ResourceGroupName rgpazewdmgiswindows001 `
    -AzureConnectionAccount AzureRunAsConnection `
    -TemplateUri 'https://raw.githubusercontent.com/MGISCAT/AZUREARMProvisioning/master/101-Single-WindowsVM-NoneDomain/SingleNoneDomainJoinedWinVMDSC.json'
    -TemplateParameterFileName 'SingleNoneDomainJoinedWinVMDSC.parameters.json'
    -ArmDeploymentName rgpazewdmgiswindows001-20161025
    -FileWorkingPath rgpazewdmgiswindows001 `
    -RepositoryResourceGroup rpgazewmgiscfgsvc001 `
    -RepositoryShareName configservice
    -ConfigDSC 'val1'
    -PlatformType 'Linux'


.NOTES
    AUTHOR: Jan Faurskov, Microsoft
    LASTEDIT: Oct 25, 2016
#>
    Param(
    [parameter(Mandatory=$true)] [string] $ResourceGroupName,
    [Parameter(Mandatory=$true)] [string] $ResourceGroupLocation,
    [parameter(Mandatory=$false)] [String] $AzureConnectionAccount,
    [parameter(Mandatory=$true)] [string] $TemplateUri,
    [parameter(Mandatory=$true)] [string] $TemplateParameterFileName,
    [parameter(Mandatory=$true)] [string] $ArmDeploymentName,
    [parameter(Mandatory=$true)] [String] $FileWorkingPath,
    [parameter(Mandatory=$true)] [String] $RepositoryResourceGroup,
    [parameter(Mandatory=$true)] [String] $RepositoryShareName,
    [parameter(Mandatory=$false)] [bool] $ConfigDSC = $true,
    [parameter(Mandatory=$false)]
    [ValidateSet("WindowsWorkgroup","WindowsDomain","Linux")]
    [string]
    $PlatFormType
        #Fixme need to receive vm admin password as string or something
       )

<##################################################################################################################################
FUNCTIONS
##################################################################################################################################>

  Function Log-ToFileFunction
  {
    param
  (
	[Parameter(Mandatory=$True)]
	[Alias('Line')]
	[String]$LogEntryToWrite,
	[Parameter(Mandatory=$True)]
	[Alias('Type')]
	[ValidateLength(1,11)]
	[String]$LogEntryType,
	[Parameter(Mandatory=$True)]
	[Alias('File')]
	[String]$Logfile
  )
  #Set path to local temp on runbook server
  $LogFile = "$env:TEMP\$Logfile"
  #write-output $logfile

    Try{
        Write-output $LogEntryToWrite
        Add-Content -Path $Logfile -Value "$((get-date).ToString("yyyy-MM-dd HH:mm:ss"))|`t$($LogEntryType)|`t$LogEntryToWrite";  
        }
    Catch
        {}
    Finally
        {}
    #get-content $logfile
  
}

Function Upload-file
{
        Param(
        [parameter(Mandatory=$true)]
        [String]
        $FileWorkingPath,
        [parameter(Mandatory=$true)]
        [String]
        $RepositoryResourceGroupName,
        [parameter(Mandatory=$true)]
        [String]
        $RepositoryShareName,
        [parameter(Mandatory=$true)]
        [String]
        $SourceFileName
        )
$SourceFilePath = "$Env:TEMP\$SourceFileName"
#fixme check if moving this outside has helped
$LoggingstorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $RepositoryResourceGroupName
$LoggingstorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $LoggingStorageAccount.ResourceGroupName -Name $LoggingStorageAccount.StorageAccountName)[0].Value
$ctx = New-AzureStorageContext $LoggingStorageAccount.StorageAccountName $LoggingstorageAccountKey
$dir = Get-AzureStorageFile -ShareName $repositorysharename -Path $FileworkingPath -Context $ctx
If(!$dir) 
    {New-AzureStorageDirectory -ShareName $repositorysharename -Path $FileworkingPath -Context $ctx}
Set-AzureStorageFileContent -ShareName $RepositoryShareName -Source $SourceFilePath -Path $FileWorkingPath -Context $ctx -Force
}

<##################################################################################################################################
MAIN BODY
##################################################################################################################################>

if($PSPrivateMetadata.JobId) {
    write-output "In Azure Automation"
   $InAzureAutomation = $true
   }
else {
   # not in Azure Automation
   write-output "NOT In Azure Automation"
   $InAzureAutomation = $false
}

$LogFileName = "New-ArmTemplateDeployment.log"

 Log-ToFileFunction -LogEntryToWrite "Starting workflow to deploy ARM template $TemplateUri" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "ResourceGroupLocation is: $ResourceGroupLocation" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "ResourceGroupName is: $ResourceGroupName" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "TemplateUri is: $TemplateUri" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "TemplateParameterFileName is: $TemplateParameterFileName" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "ArmDeploymentName is: $ArmDeploymentName" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "FileWorkingPath is: $FileWorkingPath" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "RepositoryResourceGroup is: $RepositoryResourceGroup" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "RepositoryShareName is: $RepositoryShareName" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "AzureConnectionAccount is: $AzureConnectionAccount" -LogEntryType "Information" -Logfile $LogFileName
 Log-ToFileFunction -LogEntryToWrite "ConfigDSC is: $ConfigDSC" -LogEntryType "Information" -Logfile $LogFileName

 #Get default $ErrorActionPreference for future reference
 $OldEA = $ErrorActionPreference
 #Set $ErrorActionPreference to silently continue to avoid terminating error if not logged on
 $ErrorActionPreference = 'SilentlyContinue'
 #Check if logged on
 $checklogin = Get-AzureRmContext
 #Return to old $ErrorActionPreference
 $ErrorActionPreference = $OldEA
 #If $checkLogin is empty we are not logged in, else just skip this step
 If (!$checklogin) {  
    #Connecting to ARM
    try
    {
            Log-ToFileFunction -LogEntryToWrite "Trying to log on to Azure using $AzureConnectionAccount" -LogEntryType "Information" -Logfile $LogFileName
            $Cred = Get-AutomationPSCredential -Name $AzureConnectionAccount
            Add-AzureRmAccount -Credential $Cred
            #Fixme eventually need to parameterize subscription name
            Select-AzureRmSubscription -SubScriptionID 'f626b8bb-9b1e-4710-b40c-3de7b14017a1'
    }
    catch {
            $ErrorMessage = $error[0].Exception
            Log-ToFileFunction -LogEntryToWrite $ErrorMessage -LogEntryType "Error" -Logfile $LogFileName
            throw $ErrorMessage
          }
}


Try {
    #Get Parameter file
    $guid = [Guid]::NewGuid().Guid
    $TempJSONPath = "$env:TEMP/$guid.json"
    $SourcePath = "$FileWorkingPath/$TemplateParameterFileName"
    "Connect to file repository storage..."
    $LoggingstorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $RepositoryResourceGroup
    $LoggingstorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $LoggingStorageAccount.ResourceGroupName -Name $LoggingStorageAccount.StorageAccountName)[0].Value
    $ctx = New-AzureStorageContext $LoggingStorageAccount.StorageAccountName $LoggingstorageAccountKey
    "Place contents of $SourcePath in $tempJSONPath"
    Get-AzureStorageFileContent -Context $ctx -Path $Sourcepath -ShareName $RepositoryShareName -Destination $tempJSONPath -Force
    get-content $tempJSONPath
    #If ConfigDSC is something (fixme perhaps a useful parameter), this is where we need to create a temporary SAS Token
    If($ConfigDSC)
    {
        # Get automation keyvault name
        $AutomationKeyvault = Get-AutomationVariable -Name 'Automation Keyvault'

        "ConfigDSC is $ConfigDSC generate SAS Token, and add secret keys"
        $OptionalParameters = New-Object -TypeName Hashtable
        "SAS Key"
        Set-Variable ArtifactsLocationSasTokenName '_artifactsLocationSasToken' -Option ReadOnly -Force
        $OptionalParameters.Add($ArtifactsLocationSasTokenName, $null)
        "Created the initial variable"
        # Create a SAS token for the storage container - this gives temporary read-only access to the container
  	    $ArtifactsLocationSasToken = New-AzureStorageAccountSASToken -Context $ctx -Service File -Permission r -ExpiryTime (Get-Date).AddHours(4) -Protocol HttpsOnly -ResourceType Service,Container,Object
        "SAS Token generated: $ArtifactsLocationSASToken"
        $ArtifactsLocationSasToken = ConvertTo-SecureString $ArtifactsLocationSasToken -AsPlainText -Force
        $OptionalParameters[$ArtifactsLocationSasTokenName] = $ArtifactsLocationSasToken
        "SAS Key End"

        "DCS Registration Key"
        Set-Variable AzureDSCRegistrationKeyName '_azureDSCregistrationKey' -Option ReadOnly -Force
        $OptionalParameters.Add($AzureDSCRegistrationKeyName, $null)
        "Fixme - Replace this with something from key vault"
        #$AzureDSCRegistrationKey = 'ZX+QF1gveghdBn3+c+efLM/ZJubCcveS6wDFjryCKu3B4W+YbwFc9swXzhuEnCVs5A3PL1ToeNBNGRBkBhqMXw=='
        $secret = Get-AzureKeyVaultSecret -VaultName $AutomationKeyvault -Name 'DSCRegistrationKey'
        $AzureDSCRegistrationKey = $secret.SecretValueText
	    $AzureDSCRegistrationKey = ConvertTo-SecureString $AzureDSCRegistrationKey -AsPlainText -Force
	    $OptionalParameters[$AzureDSCRegistrationKeyName] = $AzureDSCRegistrationKey
        "DCS Registration Key - END"
        
        "VMADMIN Password"
        Set-Variable VMadminPasswordName '_vmAdminPassword' -Option ReadOnly -Force
        $OptionalParameters.Add($VMadminPasswordName, $null)
        #fixme need to generate and place i KV
        $VMadminPasswordVariable = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
        $VMadminPasswordVariable
        #$VMadminPasswordVariable = 'Password12345'
        $VMadminPassword = $VMadminPasswordVariable
	    $VMadminPassword = ConvertTo-SecureString $VMadminPassword -AsPlainText -Force
        #Save in keyvault for user (fixme may want to put in VM Name instead...)
        $secret = Set-AzureKeyVaultSecret -VaultName $AutomationKeyvault -Name $ResourceGroupName -SecretValue $VMadminPassword
        #Add to optional parameters for deployment 
	    $OptionalParameters[$VMadminPasswordName] = $VMadminPassword
        "VMADMIN Password - End"

        If($PlatformType -eq 'WindowsDomain') {
            "fixme parameterize this?" 
            $JoinAccount = Get-AutomationPSCredential -Name 'AzureMGISTestDomainJoin01'
            Set-Variable DomainUserName '_domainUsername' -Option ReadOnly -Force
            $OptionalParameters.Add($DomainUserName, $null)
            #fixme Generated from something or pulled from KV
            $DomainUserNameVariable = $JoinAccount.UserName
            $DomainUserNameVariable
            $DomainUserNameVariable = ConvertTo-SecureString $DomainUserNameVariable -AsPlainText -Force
	        $OptionalParameters[$DomainUserName] = $DomainUserNameVariable
            "Domain User Name - End"
        
            #Fixme need to parameterize if domain join or not
            "Domain User Password"
            Set-Variable DomainPasswordName '_domainPassword' -Option ReadOnly -Force
            $OptionalParameters.Add($DomainPasswordName, $null)
            #Generated from something or pulled from KV
            $DomainPasswordVariable = $JoinAccount.Password
            $DomainPassword = $DomainPasswordVariable
	        #$DomainPassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
	        $OptionalParameters[$DomainPasswordName] = $DomainPassword
            "Domain User Password - End"
        }

        $ArmDeploymentCommand = 'New-AzureRmResourceGroupDeployment -Name $ArmDeploymentName `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateUri $TemplateUri `
                                    -TemplateParameterFile $TempJSONPath `
                                    @optionalParameters `
                                    -Mode Incremental `
                                    -Force'
        }
    
    Else
        {
        $ArmDeploymentCommand = 'New-AzureRmResourceGroupDeployment -Name $ArmDeploymentName `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateUri $TemplateUri `
                                    -TemplateParameterFile $TempJSONPath `
                                    -Mode Incremental `
                                    -Force'
        }
#End generate SAS token for Azure fileshare}


    Log-ToFileFunction -LogEntryToWrite "Starting deployment as follows: $ArmDeploymentCommand" -LogEntryType "Information" -Logfile $LogFileName
    "Fixme ARM Deployment Started"
    $Deployment = Invoke-Expression $ArmDeploymentCommand
    If($Deployment.ProvisioningState.ToLower() -eq 'succeeded')
        {Log-ToFileFunction -LogEntryToWrite 'Successfully deployed ARM template' -LogEntryType "Information" -Logfile $LogFileName;
            Log-ToFileFunction -LogEntryToWrite 'Runbook Success' -LogEntryType "Information" -Logfile $LogFileName}
    Else
        {   $ErrorMessage = "Deployment provisioning state is: $Deployment.ProvisioningState.ToLower()"
            Log-ToFileFunction -LogEntryToWrite $ErrorMessage -LogEntryType "Error" -Logfile $LogFileName
            throw $ErrorMessage}

    }
Catch {
            $ErrorMessage = $error[0].Exception
            Log-ToFileFunction -LogEntryToWrite $ErrorMessage -LogEntryType "Error" -Logfile $LogFileName
            throw $ErrorMessage
    }
Finally {
        
        If($InAzureAutomation) {
            Upload-File -FileWorkingPath $FileWorkingPath -RepositoryResourceGroupName $RepositoryResourceGroup -RepositoryShareName $RepositoryShareName -SourceFileName $LogFileName
            }
        }

 
    
<#Run as script
$ResourceGroupLocation = "westeurope"
$ResourceGroupName = "rpgazewdmgisdelete001"
$TemplateUri = "https://raw.githubusercontent.com/MGISCAT/AZUREARMProvisioning/master/101-Single-WindowsVM-NoneDomain/SingleNoneDomainJoinedWinVMRegisterAA.json"
$TemplateParameterFileName = 'SingleNoneDomainJoinedWinVMRegisterAA.parameters.json'
$ArmDeploymentName = "testarm04"
$FileWorkingPath = "rpgazewdmgisdelete001"
$RepositoryResourceGroup = "rpgazewmgiscfgsvc001"
$RepositoryShareName = "configsvc"
$ConfigDSC = 'Value1'
$AzureConnectionAccount = "AzureMGISProdAutomation01"

.\New-ArmTemplateDeployment.ps1 -ResourceGroupName $ResourceGroupName `
-ResourceGroupLocation $ResourceGroupLocation `
-AzureConnectionAccount $AzureConnectionAccount `
-TemplateUri $TemplateUri `
-TemplateParameterFileName $TemplateParameterFileName `
-ArmDeploymentName $ArmDeploymentName `
-FileWorkingPath $FileWorkingPath `
-RepositoryResourceGroup $RepositoryResourceGroup `
-RepositoryShareName $RepositoryShareName `
-ConfigDSC $ConfigDSC `
-Verbose
#>

<#Run as runbook
$ResourceGroupLocation = "westeurope"
$ResourceGroupName = "rpgazewdmgisdelete001"
$TemplateUri = "https://raw.githubusercontent.com/MGISCAT/AZUREARMProvisioning/master/101-Single-WindowsVM-NoneDomain/SingleNoneDomainJoinedWinVMRegisterAA.json"
$TemplateParameterFileName = 'SingleNoneDomainJoinedWinVMRegisterAA.parameters.json'
$ArmDeploymentName = "testarm04"
$FileWorkingPath = "rpgazewdmgisdelete001"
$RepositoryResourceGroup = "rpgazewmgiscfgsvc001"
$RepositoryShareName = "configsvc"
$ConfigDSC = 'Value1'
$AzureConnectionAccount = "AzureMGISProdAutomation01"

$AutomationAccount = 'aaaazewdmgisautomate-001'
$AutomationRG = 'rgpazewdmgisautomate-001'

$Params = @{"ResourceGroupLocation"="$ResourceGroupLocation";"ResourceGroupName"="$ResourceGroupName";"TemplateUri"="$TemplateUri";"TemplateParameterFileName"="$TemplateParameterFileName";"ArmDeploymentName"="$ArmDeploymentName";"FileWorkingPath"="$FileWorkingPath";"RepositoryResourceGroup"="$RepositoryResourceGroup";"repositorysharename"="$repositorysharename";"AzureConnectionAccount"="$AzureConnectionAccount";"ConfigDCS"="$ConfigDSC"}
Start-AzureRmAutomationRunbook -Name 'New-ArmTemplateDeployment' -Parameters $Params -AutomationAccountName $AutomationAccount -ResourceGroupName $AutomationRG
#>
