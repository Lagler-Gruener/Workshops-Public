    try
    {
        Write-Output "Get AzureAD automation templates"
            $cred = Get-AutomationConnection -Name "AzureRunAsConnection" -ErrorAction Stop
 
 
         Write-Output "Connect to Azure AD Tenant 'acpdemot.onmicrosoft.com'"
            Connect-AzureAD -TenantId "c4091905-68e5-4088-b43d-476ae7b152f8" -ApplicationId $cred.ApplicationId -CertificateThumbprint $cred.CertificateThumbprint -ErrorAction Stop

        Write-Output "Connect to Azure RM"
            Connect-AzAccount -Tenant "c4091905-68e5-4088-b43d-476ae7b152f8" -ApplicationId $cred.ApplicationId -CertificateThumbprint $cred.CertificateThumbprint -ServicePrincipal -ErrorAction Stop

            $subscription = Get-AzSubscription | where {$_.Name -eq "Azure CSP Demo-CloudTeam"} -ErrorAction Stop

        Write-Output "Select Subscription 'Azure CSP Demo-CloudTeam'"
            Select-AzSubscription -Subscription $subscription -ErrorAction Stop

        
        Write-Output "Remove all relevant resourcegroups"
            $rgs = Get-AzResourceGroup | where {$_.ResourceGroupName.StartsWith("AFW-Lev1-tn")}

            foreach ($rg in $rgs)
            {
                Write-Output "Get Recovery Services Vault from ResourceGroup $($rg.ResourceGroupName)"  
                $arsv = Get-AzRecoveryServicesVault -ResourceGroupName $rg.ResourceGroupName 

                foreach ($vault in $arsv)
                {
                    $vmbackups = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $vault.ID -Status Registered
                                      
                    foreach ($vmbackup in $vmbackups)
                    {
                        $backupitems = Get-AzRecoveryServicesBackupItem -Container $vmbackups -WorkloadType AzureVM -VaultId $vault.ID

                        foreach ($backupitem in $backupitems)
                        {
                            Disable-AzRecoveryServicesBackupProtection -Item $backupitem -Force -VaultId $vault.ID -RemoveRecoveryPoints
                            
                        }
                    }

                    Remove-AzRecoveryServicesVault -Vault $vault
                }

                Write-Output "Remove ResourceGroup $($rg.ResourceGroupName)"
                Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob 
            }

        Write-Output "Remove all relevant Azure AD user"
            $users = Get-AzureADUser | where {$_.DisplayName.startswith("tn")}

            foreach ($user in $users)
            {
                Write-Output $user.DisplayName
                Remove-AzureADUser -ObjectId $user.ObjectId
            }

        Write-Output "Cleanup Trainer demos"

            $trainertags = @{
                DemoFor = "Azure Level1 WS"
                Details = "Azure Level1 WS trainer demo1"
                Owner = "Hannes Lagler-Gruener"
            }

            $rgtrainer = "ACP-Demo-Level1-WS-Tr-Demo1"
            Remove-AzResourceGroup -Name $rgtrainer -Force
            New-AzResourceGroup -Name $rgtrainer -Location "West Europe" -Tag $trainertags
            
        Write-Host "Stop monitoring VMs"
            
            Stop-AzVM -Name "acpdemomon01" -ResourceGroupName "ACP-Demo-Level1-WS-Monitoring" -Force
            Stop-AzVM -Name "acpdemomon02" -ResourceGroupName "ACP-Demo-Level1-WS-Monitoring" -Force

    }
    catch
    {
        Write-Error "Error $_"
    }