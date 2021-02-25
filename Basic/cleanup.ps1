$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName   

"Logging in to Azure..."
    Add-AzAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

Select-AzSubscription -SubscriptionId "7d282253-3428-4d0f-9570-fe2de08123b3"

$ResourceGroups = Get-AzResourceGroup | where {$_.Tags.ACPWS -eq "Basic"}

foreach ($rg in $ResourceGroups) {
    Write-Output "Delete RG $($rg.ResourceGroupName)"
    Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob
}