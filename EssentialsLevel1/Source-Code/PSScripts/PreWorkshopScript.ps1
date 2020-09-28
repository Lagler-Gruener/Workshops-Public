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

    Write-Output "Create User and Resourcegroup for 12 students"

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


                $rg01 = New-AzResourceGroup -Name "AFW-Lev1-tn$i-demo1" -Location "West Europe" -ErrorAction Stop -Tag $tag
                $rg02 = New-AzResourceGroup -Name "AFW-Lev1-tn$i-demo2" -Location "West Europe" -ErrorAction Stop -Tag $tag

            Write-Output "Assign User tn$i to resourcegroup 'AFW-Lev1-tn$i-demo1'"
                New-AzRoleAssignment -ResourceGroupName $rg01.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Owner" -ErrorAction Stop

            Write-Output "Assign User tn$i to resourcegroup 'AFW-Lev1-tn$i-demo2'"
                New-AzRoleAssignment -ResourceGroupName $rg02.ResourceGroupName -ObjectId $user.ObjectId -RoleDefinitionName "Owner" -ErrorAction Stop

            Write-Output "Assign User tn$i to Azure AD Group grp-prodclt-level1-attendees"
                Add-AzureADGroupMember -RefObjectId $user.ObjectId -ObjectId "ab5ca840-6d15-4190-b9a9-56f46f1fb6d8"     
                
            Write-Output "Assign Azure Level1 Policy to ResourceGroup"
                $levelonenpolicy = Get-AzPolicySetDefinition -Name 271ef43d-8512-4f4b-be6a-259bbcd35dd9
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-Level1WS-Student-Init" -PolicySetDefinition $levelonenpolicy -Scope $rg01.ResourceId  
                New-AzPolicyAssignment -Name "ACP-CloudTeamSub-Level1WS-Student-Init" -PolicySetDefinition $levelonenpolicy -Scope $rg02.ResourceId  
        }
    }
    catch
    {
        Write-Error "Error $_"
    }


