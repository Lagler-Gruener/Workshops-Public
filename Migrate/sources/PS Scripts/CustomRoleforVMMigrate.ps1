#Custom Peering RBAC

Connect-AzAccount

Get-AzSubscription

Select-AzSubscription -SubscriptionId "bb8e13db-cd67-4923-8aea-a4d66b65cf84"

#region custom permissions for students
$role = (Get-AzRoleDefinition "Network Contributor")

$role.Id = $null
$role.Name = "Azure.RBAC.VMMigratePerm"
$role.Description = "Custom Permission for Azure VM Migrate Workshop"
$role.Actions.Clear()

$role.Actions.Add("Microsoft.RecoveryServices/register/action")
$role.Actions.Add("Microsoft.OffAzure/register/action")
$role.Actions.Add("Microsoft.KeyVault/register/action")
$role.Actions.Add("Microsoft.Migrate/register/action")


$role.AssignableScopes.Clear()

$role.AssignableScopes.Add("/subscriptions/bb8e13db-cd67-4923-8aea-a4d66b65cf84")
New-AzRoleDefinition -Role $role

#endregion

#region custom permission for trainer

$role = (Get-AzRoleDefinition "Blueprint Operator")

$role.Id = $null
$role.Name = "Azure.RBAC.VMMigratePerm-Trainer"
$role.Description = "Custom Trainer Permission for Azure VM Migrate Workshop"

$role.Actions.Remove("Microsoft.Resources/subscriptions/resourceGroups/read")

$role.AssignableScopes.Clear()

$role.AssignableScopes.Add("/subscriptions/bb8e13db-cd67-4923-8aea-a4d66b65cf84")
New-AzRoleDefinition -Role $role

#endregion


##################################################
# Update exist role
##################################################

#Connect-AzAccount

#Get-AzSubscription

#Select-AzSubscription -SubscriptionId "bb8e13db-cd67-4923-8aea-a4d66b65cf84"
#$role = (Get-AzRoleDefinition "Azure.RBAC.VMMigratePerm")
#$role.Actions.Add("Microsoft.OffAzure/register/action")

#Set-AzRoleDefinition -Role $role





