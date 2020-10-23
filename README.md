# example-voting-app-k8s

This Terraform module deploys an AKS cluster and adds support for monitoring with Log Analytics. 

## Prerequisites

* Terraform
* Azure CLI
* Service Principal (optional). To create a SP, run: ```az ad sp create-for-rbac --skip-assignment```.  

## Deployment steps

1. ```terraform init```  
2. ```terraform plan -out out.plan```  
3. Enter the SP ```appId``` and ```password``` or leave them blank. A ```SystemAssigned``` identity will be created.  
3. ```terraform apply -o out.plan```  
4. Connect to the cluster:  
```az aks get-credentials --resource-group <RESOURCE_GROUP> --name <AKS_CLUSTER_NAME>```  
5. Test connection:  
```kubectl get nodes```
6. Create dev namespace:  
```kubectl create -f voteapp-dev-namespace.yaml```
7. Save ```voteapp-dev``` namespace for all subsequent kubectl commands:  
```kubectl config set-context --current --namespace=voteapp-dev```  
8. Deploy the services:  
```kubectl create -f k8s/```
9. List ```vote``` and ```result``` external IPs:  
```kubectl get svc```
10. Open two new tabs in browser and check if it's working.

### Clean

```terraform destroy```