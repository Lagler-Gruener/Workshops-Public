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
            $rgs = Get-AzResourceGroup | where {$_.ResourceGroupName.StartsWith("AFW-Mig-tn")}

            foreach ($rg in $rgs)
            {                
                Write-Output "Remove ResourceGroup $($rg.ResourceGroupName)"
                Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob
            }

        Write-Output "Remove all Demo BluePrint ressources"
            $bprgs = Get-AzResourceGroup | where {$_.ResourceGroupName.StartsWith("ACP-Demo-Migrate-WS-DemoBP")}

            foreach ($rg in $bprgs)
            {           
                Write-Output "Remove ResourceLocks"
                Get-AzResourceLock -ResourceGroupName $rg.ResourceGroupName | Remove-AzResourceLock -Force
                 
                Write-Output "Remove ResourceGroup $($rg.ResourceGroupName)"
                Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob
            }
            

        Write-Output "Remove temp trainer User"
            $traineruser = Get-AzureADUser | where {$_.DisplayName.startswith("trn01")}
            Remove-AzureADUser -ObjectId $traineruser.ObjectId
        Write-Output "Remove all relevant Azure AD user"            
            $users = Get-AzureADUser | where {$_.DisplayName.startswith("tn")}

            foreach ($user in $users)
            {
                Write-Output $user.DisplayName
                Remove-AzureADUser -ObjectId $user.ObjectId
            }

        Write-Output "Cleanup Trainer demos"

            $trainertags = @{
                DemoFor = "Azure Migrate WS"
                Details = "Azure Migrate WS trainer demo1"
                Owner = "Hannes Lagler-Gruener"
            }

            $rgtrainer = "ACP-Demo-Migrate-WS-Tr-Demo1"
            $rgtrainer2 = "ACP-Demo-Migrate-WS-Tr-Demo1-mig"
            Remove-AzResourceGroup -Name $rgtrainer -Force
            New-AzResourceGroup -Name $rgtrainer -Location "West Europe" -Tag $trainertags  

            Remove-AzResourceGroup -Name $rgtrainer2 -Force
            New-AzResourceGroup -Name $rgtrainer2 -Location "West Europe" -Tag $trainertags  
            
        Write-Output "Cleanup Azure AD Applications"  
            $apps = Get-AzureADApplication -All $true
            
            foreach ($app in $apps)
            {
                if ($app.Displayname.StartsWith("demomig-"))
                {
                    Write-Output "Delete App: $($app.DisplayName)"
                    Remove-AzureADApplication -ObjectId $app.ObjectId
                }
            }        

    }
    catch
    {
        Write-Error "Error $_"
    }