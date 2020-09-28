    Param (   
        [parameter(Mandatory=$true)] 
        [String]  
        $StudentCount
    )

 
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


    #region Create trainer ressources

    $trainerrg = Get-AzResourceGroup -Name "ACP-Demo-Migrate-WS-Tr-Demo1" -Location "West Europe"
    $trainerrgmig = Get-AzResourceGroup -Name "ACP-Demo-Migrate-WS-Tr-Demo1-mig" -Location "West Europe"
    $trainerrgdashboard = Get-AzResourceGroup -Name "ACP-Dashboards" -Location "West Europe"



    Write-Output "Create Trainer demo ressources"
        
        Write-Output "Create user trn01"
                $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
                $PasswordProfile.Password = "AzFundamentalsWs01"
                $PasswordProfile.ForceChangePasswordNextLogin = $true
        $user = New-AzureADUser -DisplayName "trn01" -PasswordProfile $PasswordProfile -UserPrincipalName "trn01@demo.acp.at" -AccountEnabled $true -MailNickName "trn01" -ErrorAction Stop

        Write-Output "Assign User trn01 to required resourcegroups"
                New-AzRoleAssignment -ResourceGroupName $trainerrg.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Contributor" -ErrorAction Stop
                New-AzRoleAssignment -ResourceGroupName $trainerrgmig.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Contributor" -ErrorAction Stop
                New-AzRoleAssignment -ResourceGroupName $trainerrgdashboard.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Contributor" -ErrorAction Stop
           

        Write-Output "Assign Azure Migration Policy to ResourceGroup"
                $migrationpolicy = Get-AzPolicySetDefinition -Name 412eb9e3-10f3-4052-b516-f19620d1a48f
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-MigrationWS-Student-Init" -PolicySetDefinition $migrationpolicy -Scope $trainerrg.ResourceId
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-MigrationWS-Student-Init" -PolicySetDefinition $migrationpolicy -Scope $trainerrgmig.ResourceId

        Write-Output "Assign User trn01 to Azure AD Group grp-prodclt-vmmigrate-attendees"
                Add-AzureADGroupMember -RefObjectId $user.ObjectId -ObjectId "1addda3b-ad14-4c7f-b7f0-8726155eda32"  

        Write-Output "Assign User trn01 to Azure AD Group grp-prodclt-vmmigrate-trainer"
                Add-AzureADGroupMember -RefObjectId $user.ObjectId -ObjectId "c40f239c-b230-4467-a16c-873831d41f50"  
                
        Write-Output "Assign User trn01 to Azure AD Role Application developer"
                Add-AzureADDirectoryRoleMember -RefObjectId $user.ObjectId -ObjectId "86ec04f7-a62b-48e0-a401-69f5d2f6a82f"
                


        $templateFilePath = "https://straccdemomigratewscont.blob.core.windows.net/armtemplate/hypervdeploy.json"

        $params = @{
               studentname = "trn01"
               usertype = "trainer"
            }   

        
        New-AzResourceGroupDeployment -ResourceGroupName $trainerrg.ResourceGroupName -AsJob -Name "deployment-trn01" -TemplateUri $templateFilePath -TemplateParameterObject $params


    #endregion


    #region create student ressource

    Write-Output "Create User and Resourcegroup for $StudentCount students"        

    For ($i=1; $i -le $StudentCount; $i++) {
        
            Write-Output "Create user tn$i"
                $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
                $PasswordProfile.Password = "AzFundamentalsWs01"
                $PasswordProfile.ForceChangePasswordNextLogin = $true

                $user = New-AzureADUser -DisplayName "tn$i" -PasswordProfile $PasswordProfile -UserPrincipalName "tn$i@demo.acp.at" -AccountEnabled $true -MailNickName "tn$i" -ErrorAction Stop

        

            Write-Output "Create resourcegroup for User tn$i"

                $tag = @{
                            DemoFor = "tn$i Hands-On";
                            Details = "Hands-On Demo RG";
                            Owner = "tn$i"
                        }


                $rg01 = New-AzResourceGroup -Name "AFW-Mig-tn$i-demo1" -Location "West Europe" -ErrorAction Stop -Tag $tag
                $rg02 = New-AzResourceGroup -Name "AFW-Mig-tn$i-demo1-mig" -Location "West Europe" -ErrorAction Stop -Tag $tag

            Write-Output "Assign User tn$i to resourcegroup 'AFW-tn$i-demo1'"
                New-AzRoleAssignment -ResourceGroupName $rg01.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Contributor" -ErrorAction Stop
                New-AzRoleAssignment -ResourceGroupName $rg02.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Contributor" -ErrorAction Stop
           

            Write-Output "Assign Azure Migration Policy to ResourceGroup"
                $migrationpolicy = Get-AzPolicySetDefinition -Name 412eb9e3-10f3-4052-b516-f19620d1a48f
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-MigrationWS-Student-Init" -PolicySetDefinition $migrationpolicy -Scope $rg01.ResourceId
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-MigrationWS-Student-Init" -PolicySetDefinition $migrationpolicy -Scope $rg02.ResourceId

            Write-Output "Assign User tn$i to Azure AD Group grp-prodclt-vmmigrate-attendees"
                Add-AzureADGroupMember -RefObjectId $user.ObjectId -ObjectId "1addda3b-ad14-4c7f-b7f0-8726155eda32"  
                
            Write-Output "Assign User tn$i to Azure AD Role Application developer"
                Add-AzureADDirectoryRoleMember -RefObjectId $user.ObjectId -ObjectId "86ec04f7-a62b-48e0-a401-69f5d2f6a82f"
                

            $params = @{
               studentname = "tn$i"
               usertype = "student"
            }            

            New-AzResourceGroupDeployment -ResourceGroupName $rg01.ResourceGroupName -AsJob -Name "deployment-tn$i" -TemplateUri $templateFilePath -TemplateParameterObject $params            
        }
    }
    catch
    {
        Write-Error "Error $_"
    }

    #endregion


