###################################################################################################
#                              Azure Login
#
#
    Login-AzAccount
    Get-AzSubscription
    Select-AzSubscription -Subscription "Azure CSP Demo-CloudTeam"
#
#
#
###################################################################################################

#region import required modules

Import-Module Az.Storage
Import-Module AzTable

#Azure Stack Storage Account
$key = Get-AzKeyVaultSecret -VaultName "ACP-Demo-Level1-KeyVault" -Name "level1stracckey" 

    #Decrypt secure string
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($key.SecretValue)
    $straccconnectionstring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$ctx = New-AzStorageContext -ConnectionString $straccconnectionstring

#endregion

#region Sample for Blob Storage

$localFileDirectory = "C:\temp\hybriddemo"
$ContainerName = "essentiallevel1demo"    


foreach ($file in (Get-ChildItem -Path $localFileDirectory))
{
    if($null -eq (Get-AzStorageContainer -Context $ctx | Where-Object { $_.Name -eq $ContainerName }))
    {        
        New-AzStorageContainer -Context $ctx -Name $ContainerName
    }
    
    Set-AzStorageBlobContent -File $file.FullName -Container $ContainerName -Blob $file.Name -Context $ctx -Force
}

#Get blobs from storage account container
Get-AzStorageBlob -Context $ctx -Container $ContainerName

#Delete all blobs from container
foreach ($blob in (Get-AzStorageBlob -Context $ctx -Container $ContainerName))
{
    Remove-AzStorageBlob -Container $ContainerName -Force -Blob $blob.Name -Context $ctx
}    


#Get blobs from storage account container
Get-AzStorageBlob -Context $ctx -Container $ContainerName

#endregion

#region Sample for Azure Storage Table
$tableName = "azessentialslevel1"
$partitionKey = "Client"

if($null -eq (Get-AzStorageTable -Name $tableName -Context $ctx -ErrorAction SilentlyContinue))
{
    New-AzStorageTable –Name $tableName –Context $ctx
}

#Get Azure Storage Table
$tableName = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable

#Add items to table
    Add-AzTableRow `
        -table $tableName `
        -partitionKey $partitionKey `
        -rowKey ("CA") -property @{"username"="Chris";"userid"=1}

    Add-AzTableRow `
        -table $tableName `
        -partitionKey $partitionKey `
        -rowKey ("NM") -property @{"username"="Jessie";"userid"=2}

#Get all rows
    Get-AzTableRow -table $tableName | ft

#Delete single row
    [string]$filter = `
    [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("username",`
    [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Jessie")
    
    $userToDelete = Get-AzTableRow -table $tableName `
                                   -customFilter $filter

    Remove-AzTableRow -table $tableName -entity $userToDelete

#Get all rows
    Get-AzTableRow -table $tableName | ft

#Delete all rows
    Get-AzTableRow -table $tableName | Remove-AzTableRow -table $tableName 

#Get all rows
    Get-AzTableRow -table $tableName | ft        

#endregion

#region Sample for Azure Storage Queue

$queueName = "azessentialslevel1"

# Retrieve a specific queue
if($null -eq (Get-AzStorageQueue –Name $queueName –Context $ctx -ErrorAction SilentlyContinue))
{
    New-AzStorageQueue -Name $queueName –Context $ctx
}

$queue = Get-AzStorageQueue –Name $queueName –Context $ctx

# Show the properties of the queue
$queue

# Retrieve all queues and show their names
Get-AzStorageQueue -Context $ctx | Select-Object Name

# Add Message to queue
$message = "Testmessage1"

$queueMessage = New-Object -TypeName "Microsoft.Azure.Storage.Queue.CloudQueueMessage,$($queue.CloudQueue.GetType().Assembly.FullName)" `
                           -ArgumentList $message
# Add a new message to the queue
$queue.CloudQueue.AddMessageAsync($QueueMessage)    


#Read queue
$queueMessage = $queue.CloudQueue.GetMessageAsync($null,$null,$null)
$queueMessage.Result.AsString

#Delete Message from queue
$queue.CloudQueue.DeleteMessageAsync($queueMessage.Result.Id,$queueMessage.Result.popReceipt)

#endregion