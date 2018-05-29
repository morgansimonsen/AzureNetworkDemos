# Standarb LB zonal redundant frontend
# zonal means deployed to a specific zone
# you specify zones

#!/bin/bash
base=StandardLB-Zonal
rg="RG-$base"
location=westeurope

# create rg
echo -e "\x1B[01;95m create rg \x1B[0m"
az group create \
--name $rg \
--location $location

# create zonal public ip
# the ip is deployed in a zone
echo -e "\x1B[01;95m create public ip; since a zone is specified it becomes a zonal ip \x1B[0m"
az network public-ip create \
--resource-group $rg \
--name "PIP-$base" \
--sku Standard
--zone 1

# create lb
echo -e "\x1B[01;95m create lb \x1B[0m"
az network lb create \
--resource-group $rg \
--name "LB-$base" \
--public-ip-address "PIP-$base" \
--frontend-ip-name "FE-$base" \
--backend-pool-name "BEP-$base" \
--sku Standard

# create health probe
echo -e "\x1B[01;95m create health probe \x1B[0m"
az network lb probe create \
--resource-group $rg \
--lb-name "LB-$base" \
--name "HP-$base" \
--protocol tcp \
--port 80

# create lb rule
echo -e "\x1B[01;95m create lb rule \x1B[0m"
az network lb rule create \
--resource-group $rg \
--lb-name "LB-$base" \
--name "LBRule-$base-web" \
--protocol tcp \
--frontend-port 80 \
--backend-port 80 \
--frontend-ip-name "FE-$base" \
--backend-pool-name "BEP-$base" \
--probe-name "HP-$base"

# create vnet
echo -e "\x1B[01;95m create vnet \x1B[0m"
az network vnet create \
--resource-group $rg \
--location $location \
--name "vNet-$base" \
--subnet-name "subnet1-$base"

# create nsg
echo -e "\x1B[01;95m create nsg \x1B[0m"
az network nsg create \
--resource-group $rg \
--name "NSG-$base"

# create nsg rule
echo -e "\x1B[01;95m create nsg rule \x1B[0m"
az network nsg rule create \
--resource-group $rg \
--nsg-name "NSG-$base" \
--name "NSG-Rule-$base" \
--protocol tcp \
--direction inbound \
--source-address-prefix '*' \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 80 \
--access allow \
--priority 200

# create nics
echo -e "\x1B[01;95m create nics \x1B[0m"
for i in `seq 1 3`; do
    az network nic create \
        --resource-group $rg \
        --name "NIC-$base-$i" \
        --vnet-name "vNet-$base" \
        --subnet "subnet1-$base" \
        --network-security-group "NSG-$base" \
        --lb-name "LB-$base" \
        --lb-address-pools "BEP-$base"
done

# create zonal vms
echo -e "\x1B[01;95m create zonal vms; all in the same zone \x1B[0m"
for i in `seq 1 3`; do
  az vm create \
    --resource-group $rg \
    --name "VM-$i" \
    --nics "NIC-$base-$i" \
    --image UbuntuLTS \
    --size "Standard_B1s" \
    --generate-ssh-keys \
    --zone 1 \
    --custom-data cloud-init.yml
done

# test
echo -e "\x1B[01;95m test \x1B[0m"
az network public-ip show \
    --resource-group $rg \
    --name "PIP-$base" \
    --query [ipAddress] \
    --output tsv