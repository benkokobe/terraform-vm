# Doc
# https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/virtual-machines/linux/provisioner


prefix="$1"
state_filename="${prefix}.tfstate"

terraform refresh -state=${state_filename}
terraform apply -auto-approve -state=${state_filename} 

terraform destroy -state=${state_filename}

#Info Azure
az account show --query '{tenantId:tenantId,subscriptionid:id}';

#launch
terraform init
terraform refresh -state=centosvm.tfstate
terraform apply -auto-approve -state=centosvm.tfstate
terraform destroy -state=centosvm.tfstate

# creation of backend
export RESOURCE_GROUP_NAME='bko-state'
export STORAGE_ACCOUNT_NAME='bkostate'
export CONTAINER_NAME='tstate'

az group create --name $RESOURCE_GROUP_NAME --location "West Europe"
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
export ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY