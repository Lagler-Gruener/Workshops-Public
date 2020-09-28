#Custom Peering RBAC

Login-AzureRmAccount

$role = (Get-AzureRmRoleDefinition "Network Contributor")

$role.Id = $null
$role.Name = "Azure.RBAC.VMDscOnboardCustom"
$role.Description = "Custom Permission to onboad VM into Azure Automation DSC"
$role.Actions.Clear()
$role.Actions.Add("Microsoft.Resources/deployments/*")
$role.Actions.Add("Microsoft.Resources/subscriptions/resourceGroups/write")
$role.Actions.Add("Microsoft.Automation/automationAccounts/read")
$role.Actions.Add("Microsoft.OperationalInsights/workspaces/intelligencepacks/read")
$role.Actions.Add("Microsoft.OperationalInsights/workspaces/write")
$role.Actions.Add("Microsoft.Automation/automationAccounts/write")
$role.Actions.Add("Microsoft.Automation/automationAccounts/nodes/write")
$role.Actions.Add("Microsoft.Insights/register/action")


$role.AssignableScopes.Clear()

$role.AssignableScopes.Add("/subscriptions/24464ef0-3fec-4a59-9338-3b3b98606a2d")
New-AzureRmRoleDefinition -Role $role



$role = (Get-AzureRmRoleDefinition "Azure.RBAC.VMDscOnboardCustom")



