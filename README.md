# Elastic Cloud Enterprise setup script for Microsoft Azure

This is a set of automation tools and scripts that will automate the creation of the Azure environment for Elastic Cloud Enterprise (ECE).

## Terraform-based deployment

This method uses Packer to generate a base image with all the pre-requisites, and a Terraform configuration to deploy the Azure resources. It requires to prepare the image up front, but makes the deployment itself much faster since the OS is already prepared.

### Preparing the environment

This method require you to first define some environment variables to authorize Packer and Terraform to access Azure.

```
export ARM_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
export ARM_CLIENT_ID=00000000-0000-0000-0000-000000000000
export ARM_CLIENT_SECRET=00000000-0000-0000-0000-000000000000
export ARM_TENANT_ID=00000000-0000-0000-0000-000000000000
```

### Run Packer

First create a Resource Group:

```
az group create -n ece-base-image -l westeurope
```

Make sure you use the same name and location as used in the Packer configuration.

Then run Packer:

```
packer build ece-packer.json
```

Once the VM image has been created, retrieve its ID using the following command:

```
az vm image list -g ece-base-image
```

The ID will have this form:

```
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/ece-base-image/providers/Microsoft.Compute/images/ece-base-image
```

### Run Terraform

Copy the image ID into the `storage_image_reference` resource configuration. It should look like this:

```
  storage_image_reference {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/ece-base-image/providers/Microsoft.Compute/images/ece-base-image"
  }
```

Then run Terraform:

```
terraform apply
```

The Terraform configuration will execute the `disk_setup.sh` script in order to format the data disk. The script will also change the Docker configuration to point to the newly created data directory.

## Script-based deployment

This method uses the `az` command to provision the ECE resources in Azure. It uses base Ubuntu images and prepares them according to the ECE documentation.

### Provisioning the resources

Run `provision.sh` to provision three Virtual Machines ready to be used to deploy ECE, including networking, security, and OS pre-requisites. The `node_setup.sh` and `disk_setup.sh` scripts will be executed on each VM in order to prepare the OS. Each VM will be rebooted for the system settings to take effect.

## Installing ECE

Once the machines are prepared, you can log into them to install ECE.

To find the public IP addresses allocated to the nodes, use the following command:

```
az network public-ip list -g ece --query '[].ipAddress'
```

Log into the first machine and change to the `elastic` user:

```
sudo su - elastic
```

Then install ECE on the first host using the following commands:

```
curl -O https://download.elastic.co/cloud/elastic-cloud-enterprise.sh
chmod +x ./elastic-cloud-enterprise.sh
./elastic-cloud-enterprise.sh install --host-storage-path /data/elastic
```

Then follow the ECE instructions to install on all the hosts.

## Disclaimer

This is just an example and not officially supported by Elastic nor Microsoft.
