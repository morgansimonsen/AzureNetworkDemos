# Select subscription
az account set --subscription 3cf46281-f639-44bc-a338-11697697bb2a

# Create resource groups
az group create --name MVPDay-RG1 --location northeurope --tags Environment=Test;Project=MVPDay2017

# Create public IP for GW
az network public-ip create -g MVPDay-RG1 -n PIP-vNetGW --allocation-method Static --tags Environment=Test;Project=MVPDay2017

