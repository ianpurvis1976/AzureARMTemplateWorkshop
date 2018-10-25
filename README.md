# MnB-Khameleon

#*****************************************************
#CLI to create a resource group
# sign into azure
az login

#set up variables
rg=<name of resource group>
location=<azure region code>

#command to create resource group
az group create --name $rg --location $location


#*****************************************************
#CLI to run the template with associated parameters file

# Step1. cd to the folder containing your template files
dir=$(pwd)
template=$dir/azuredeploy.json
parms=$dir/azuredeploy.parameters.json
r
az group deployment create --parameters "@$parms" --template-file $template --resource-group $rg --name $job


#example of passing in parameters at run time
az group deployment create --parameters "@$parms" --parameters vmName=lab5UbuntuVm1 numberOfDataDisks=2 --template-file $template --resource-group $rg --name $job

#or simply:

az group deployment create --mode Complete --parameters azuredeploy.parameters.json --template-file azuredeploy.json --resource-group $rg --name $job



az group deployment create --parameters azuredeploy.parameters.json --parameters vmName=RDPJumpServer numberOfDataDisks=1 dnsLabelPrefix=ianpurvistest1232 --template-file azuredeploy.json --resource-group $rg --name $job

az network nic create --resource-group $rg --name rdpjumpserver-nic --subnet dmzSubnet --vnet-name MitchellsAndButlersVnet

az group deployment create --parameters azuredeploy.parameters.json --parameters vmName=RDPJumpServer numberOfDataDisks=1 dnsLabelPrefix=ianpurvistest1232 appDnsNameforLBIP=mywebappip123 --template-file azuredeploy.json --resource-group $rg --name $job