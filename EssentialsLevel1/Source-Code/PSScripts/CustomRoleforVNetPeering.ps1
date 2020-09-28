#Custom Peering RBAC

Login-AzureRmAccount

$role = (Get-AzureRmRoleDefinition "Network Contributor")

$role.Id = $null
$role.Name = "Azure.RBAC.VNetPeeringCustom"
$role.Description = "Custom Permission to assign VNetPeering"
$role.Actions.Clear()
$role.Actions.Add("Microsoft.Network/VirtualNetworks/VirtualNetworkPeerings/write")
$role.Actions.Add("Microsoft.Network/VirtualNetworks/VirtualNetworkPeerings/read")
$role.Actions.Add("Microsoft.Network/virtualNetworks/peer/action")


$role.AssignableScopes.Clear()

$role.AssignableScopes.Add("/subscriptions/24464ef0-3fec-4a59-9338-3b3b98606a2d")
New-AzureRmRoleDefinition -Role $role





