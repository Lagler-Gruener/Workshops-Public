Connect-AzAccount

Get-AzSubscription

Select-AzSubscription -Subscription "Azure CSP Demo-CloudTeam"

Get-AzResourceGroup | Select-Object ResourceGroupName

#Get-AzResource -ResourceGroupName AFW-Trainer-content | Select-Object Name, ResourceType

$rule = New-AzNetworkSecurityRuleConfig -Name "Rule1" `
                                        -Description "Allow Port 80" `
                                        -Protocol Tcp `
                                        -SourcePortRange * `
                                        -DestinationPortRange 80 `
                                        -SourceAddressPrefix Internet  `
                                        -DestinationAddressPrefix * `
                                        -Access Allow `
                                        -Priority 100 `
                                        -Direction Inbound

New-AzNetworkSecurityGroup -Name "AFW-Demo-NSG" -ResourceGroupName ACP-Demo-Level1-WS-Tr-Demo1 -Location WestEurope -SecurityRules $rule -Verbose