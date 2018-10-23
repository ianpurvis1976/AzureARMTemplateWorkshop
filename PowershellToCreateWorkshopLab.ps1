
$rgName = "MitchellsAndButlersRGShell"
$subnet1Name = "gatewaySubnetShell"
$subnet2Name = "dmzSubnetShell"
$subnet3Name = "appSubnetShell"
$subnet4Name = "dataSubnetShell"

$subnet1AddressPrefix = "10.1.0.0/24"
$subnet2AddressPrefix = "10.1.1.0/27"
$subnet3AddressPrefix = "10.1.2.0/24"
$subnet4AddressPrefix = "10.1.3.0/26"

$vnetAddressSpace = "10.1.0.0/16"
$VNetName = "MitchellsAndButlersVnetShell"

$location = "East US"
$myIPAddress ="5.69.243.59"


#Connect-AzureRmAccount
New-AzureRmResourceGroup -Name $rgName -Location $location


#Create subnets
$gwSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnet1AddressPrefix
$dmzSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix $subnet2AddressPrefix
$appSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet3Name -AddressPrefix $subnet3AddressPrefix
$dataSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet4Name -AddressPrefix $subnet4AddressPrefix


#Associate with vnet
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name VNetName -AddressPrefix $vnetAddressSpace `
  -Location $location -Subnet $gwSubnet, $dmzSubnet, $appSubnet, $dataSubnet




##Create LB
##-----------



#Create a public IP address

$publicIP = New-AzureRmPublicIpAddress `
  -ResourceGroupName $rgName `
  -Location $location `
  -AllocationMethod "Dynamic" `
  -Name "myPublicIP"
  
#Create frontend IP
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig `
  -Name "myFrontEnd" `
  -PublicIpAddress $publicIP
  
#Configure backend address pool to attach VMs to
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "myBackEndPool"

#Create a health probe which will remove vm from pool if webpage doesnt respond with 200
$probe = New-AzureRmLoadBalancerProbeConfig `
  -Name "myHealthProbe" `
  -RequestPath healthcheck2.aspx `
  -Protocol http `
  -Port 80 `
  -IntervalInSeconds 16 `
  -ProbeCount 2
  
#Create LB Rule to distribute traffic
$lbrule = New-AzureRmLoadBalancerRuleConfig `
  -Name "myLoadBalancerRule" `
  -FrontendIpConfiguration $frontendIP `
  -BackendAddressPool $backendPool `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80 `
  -Probe $probe

#Create NAT Rules for port forwarding

$natrule1 = New-AzureRmLoadBalancerInboundNatRuleConfig `
-Name 'myLoadBalancerRDP1' `
-FrontendIpConfiguration $frontendIP `
-Protocol tcp `
-FrontendPort 4221 `
-BackendPort 3389

$natrule2 = New-AzureRmLoadBalancerInboundNatRuleConfig `
-Name 'myLoadBalancerRDP2' `
-FrontendIpConfiguration $frontendIP `
-Protocol tcp `
-FrontendPort 4222 `
-BackendPort 3389


#create LB
$lb = New-AzureRmLoadBalancer `
-ResourceGroupName $rgName `
-Name 'MyLoadBalancer' `
-Location $location `
-FrontendIpConfiguration $frontendIP `
-BackendAddressPool $backendPool `
-Probe $probe `
-LoadBalancingRule $lbrule `
-InboundNatRule $natrule1,$natrule2

#Create a network
# Create subnet config
#$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
#  -Name "mySubnet" `
#  -AddressPrefix 10.0.2.0/24

# Create the virtual network
#$vnet = New-AzureRmVirtualNetwork `
#  -ResourceGroupName "myResourceGroupLB" `
#  -Location "EastUS" `
#  -Name "myVnet" `
#  -AddressPrefix 10.0.0.0/16 `
#  -Subnet $subnetConfig
  
  
#Create a network security group rules 
$rule1 = New-AzureRmNetworkSecurityRuleConfig `
-Name 'myNetworkSecurityGroupRuleRDP' `
-Description 'Allow RDP' `
-Access Allow `
-Protocol Tcp `
-Direction Inbound `
-Priority 1000 `
-SourceAddressPrefix $myIPAddress `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 3389

$rule2 = New-AzureRmNetworkSecurityRuleConfig `
-Name 'myNetworkSecurityGroupRuleHTTP' `
-Description 'Allow HTTP' `
-Access Allow `
-Protocol Tcp `
-Direction Inbound `
-Priority 2000 `
-SourceAddressPrefix Internet `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 80

#Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup `
-ResourceGroupName $rgName `
-Location $location `
-Name 'myNetworkSecurityGroup' `
-SecurityRules $rule1,$rule2

#Create NICs

# Create NIC for VM1
$nicVM1 = New-AzureRmNetworkInterface `
-ResourceGroupName $rgName `
-Location $location `
-Name 'MyNic1' `
-LoadBalancerBackendAddressPool $backendPool `
-NetworkSecurityGroup $nsg `
-LoadBalancerInboundNatRule $natrule1 `
-Subnet $vnet.Subnets[2]

# Create NIC for VM2
$nicVM2 = New-AzureRmNetworkInterface `
-ResourceGroupName $rgName `
-Location $location `
-Name 'MyNic2' `
-LoadBalancerBackendAddressPool $backendPool `
-NetworkSecurityGroup $nsg `
-LoadBalancerInboundNatRule $natrule2 `
-Subnet $vnet.Subnets[2]


#Create AvailabilitySet

$availabilitySet = New-AzureRmAvailabilitySet `
  -ResourceGroupName $rgName `
  -Name "myAvailabilitySet" `
  -Location $location `
  -Sku aligned `
  -PlatformFaultDomainCount 2 `
  -PlatformUpdateDomainCount 2

#set creds
$cred = Get-Credential

#create vms
for ($i=1; $i -le 2; $i++)
{
    New-AzureRmVm `
        -ResourceGroupName $rgName `
        -Name "myVM$i" `
        -Location $location `
        -VirtualNetworkName $VNetName `
        -SubnetName $subnet3Name `
        -SecurityGroupName "myNetworkSecurityGroup" `
        -OpenPorts 80 `
        -AvailabilitySetName "myAvailabilitySet" `
        -Credential $cred `
        -AsJob
}

