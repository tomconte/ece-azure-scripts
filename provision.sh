#!/bin/bash

# Tip: run with `bash -x` to monitor progress

# Provision Azure resources for Elastic Cloud Enterprise (ECE)

resource_group_name="ece"
location="westeurope"

image="Canonical:UbuntuServer:16.04-LTS:latest"
disk_size=128
vm_size="Standard_D11_v2"

# Resource Group

az group create --name ${resource_group_name} --location ${location}

# Network Security Group

az network nsg create --resource-group ${resource_group_name} --name nsg-ece --location ${location}

# Network Security Rules

az network nsg rule create --resource-group ${resource_group_name} --nsg-name nsg-ece --name ssh \
    --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet \
    --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22
az network nsg rule create --resource-group ${resource_group_name} --nsg-name nsg-ece --name https \
    --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet \
    --source-port-range "*" --destination-address-prefix "*" --destination-port-range 12443
az network nsg rule create --resource-group ${resource_group_name} --nsg-name nsg-ece --name ece-frontend \
    --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet \
    --source-port-range "*" --destination-address-prefix "*" --destination-port-range 9243
az network nsg rule create --resource-group ${resource_group_name} --nsg-name nsg-ece --name admin-ui \
    --access Allow --protocol Tcp --direction Inbound --priority 400 --source-address-prefix Internet \
    --source-port-range "*" --destination-address-prefix "*" --destination-port-range 12400

# Virtual Network

az network vnet create --resource-group ${resource_group_name} --name vnet-ece \
    --address-prefix 10.0.0.0/16 --subnet-name default
az network vnet subnet update --resource-group ${resource_group_name} --vnet-name vnet-ece \
    --name default --network-security-group nsg-ece

# Virtual Machines

for i in ece-node-01 ece-node-02 ece-node-03
do
    # Create VM
    az vm create --resource-group ${resource_group_name} --name $i \
        --image ${image} --size ${vm_size} \
        --data-disk-sizes-gb ${disk_size} --public-ip-address-allocation static --vnet-name vnet-ece \
        --subnet default --nsg nsg-ece --admin-user azureuser

    # Run node setup script
    az vm run-command invoke -g ${resource_group_name} -n $i --command-id RunShellScript --scripts @node_setup.sh

    # Run disk setup script
    az vm run-command invoke -g ${resource_group_name} -n $i --command-id RunShellScript --scripts @disk_setup.sh

    # Reboot
    az vm restart -g ${resource_group_name} -n $i
done
