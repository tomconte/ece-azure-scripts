# Elastic Cloud Enterprise setup script for Microsoft Azure

This is a set of scripts that will automate the creation of the Azure environment for Elastic Cloud Enterprise (ECE).

Run `provision.sh` to provision three Virtual Machines ready to be used to deploy ECE, including networking, security, and OS pre-requisites. The `node_setup.sh` script will be executed on each VM in order to prepare the OS. Each VM will be rebooted for the system settings to take effect.

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



Disclaimer: this is just an example. YMMV.
