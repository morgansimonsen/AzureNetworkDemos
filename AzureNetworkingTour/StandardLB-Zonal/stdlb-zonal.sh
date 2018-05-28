#!/bin/bash
base=StandardLB-Zonal
rg="RG-$base"
location=westeurope

# create rg
echo "create rg"
az group create \
--name $rg \
--location $location

# create public ip
echo "create public ip"
az network public-ip create \
--resource-group $rg \
--name "PIP-$base" \
--sku Standard

# create lb
echo "create lb"
az network lb create \
--resource-group $rg \
--name "LB-$base" \
--public-ip-address "PIP-$base" \
--frontend-ip-name "FE-$base" \
--backend-pool-name "BEP-$base" \
--sku Standard

# create health probe
echo "create health probe"
az network lb probe create \
--resource-group $rg \
--lb-name "LB-$base" \
--name "HP-$base" \
--protocol tcp \
--port 80

# create lb rule
echo "create lb rule"
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
echo "create vnet"
az network vnet create \
--resource-group $rg \
--location $location \
--name "vNet-$base" \
--subnet-name "subnet1-$base"

# create nsg
echo "create nsg"
az network nsg create \
--resource-group $rg \
--name "NSG-$base"

# create nsg rule
echo "create nsg rule"
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
echo "create nics"
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
echo "create zonal vms"
for i in `seq 1 3`; do
  az vm create \
    --resource-group $rg \
    --name "VM-$i" \
    --nics "NIC-$base-$i" \
    --image UbuntuLTS \
    --size "Standard_A2_v2"
    --generate-ssh-keys \
    --zone $i \
    --custom-data cloud-init.yml
done

# test
echo "test"
az network public-ip show \
    --resource-group $rg \
    --name "PIP-$base" \
    --query [ipAddress] \
    --output tsv