# Spring Boot PetClinic Application Deployed to Azure Kubernetes Service (AKS)
## Description 
In this sample app template, the PetClinic application (a Spring Boot based app) is containerized and deployed to a AKS cluster secured by Azure Firewall

## Deploy Spring Boot apps using Azure Kubernetes Service and Azure Services:

--
Tech stack:

- Azure
- Azure PostgreSQL DB
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Azure Infra (Vnet/Subnet)
- Azure Fire Wall
- Azure Bastion
- Github Actions
- Bicep
- Docker
- Maven
- Springboot

---

## Introduction

This is a quickstart template. It deploys the following:

* Deploying PetClinic App:
  * Database configuration
  * Provisioning Azure Infra Services  
  * Create the spring-petclinic-AKS App on Docker
  * Create an Azure Container Registry
  * Push your app to the container registry
  * Create a Kubernetes Cluster on AKS
  * Deploy the image to your Kubernetes cluster
  * Verify your container image

* PetClinic on Automated CI/CD with GitHub Action  
  * CI/CD on GitHub Action
  * CI/CD in action with the app

> Refer to the [App Templates](https://github.com/microsoft/App-Templates) repo Readme for more samples that are compatible with [AzureAccelerators](https://github.com/Azure/azure-dev/).

## Prerequisites
- Local shell with Azure CLI installed or [Azure Cloud Shell](https://ms.portal.azure.com/#cloudshell/)
- Azure Subscription, on which you are able to create resources and assign permissions
  - View your subscription using ```az account show``` 
  -  If you don't have an account, you can [create one for free](https://azure.microsoft.com/free).  

## Getting Started
### Fork the repository

Fork the repository by clicking the 'Fork' button on the top right of the page.
This creates a local copy of the repository for you to work in. 

### Azure Configuration for GitHub  

The newly created GitHub repo uses GitHub Actions to deploy Azure resources and application code automatically. Your subscription is accessed using an Azure Service Principal. This is an identity created for use by applications, hosted services, and automated tools to access Azure resources. The following steps show how to [set up GitHub Actions to deploy Azure applications](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md)

Create an [Azure Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) with **contributor** permissions on the subscription. The subscription-level permission is needed because the deployment includes creation of the resource group itself.
 * Run the following [az cli](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) command, either locally on your command line or on the Cloud Shell. 
   Replace {subscription-id} with the id of the subscription in GUID format. {service-principal-name} can be any alfanumeric string, e.g. GithubPrincipal
    ```bash  
       az ad sp create-for-rbac --name {service-principal-name} --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth      
      ```
 * The command should output a JSON object similar to this:
 ```
      {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        "activeDirectoryEndpointUrl": "<URL>",
        "resourceManagerEndpointUrl": "<URL>",
        "activeDirectoryGraphResourceId": "<URL>",
        "sqlManagementEndpointUrl": "<URL>",
        "galleryEndpointUrl": "<URL>",
        "managementEndpointUrl": "<URL>"
      }
   ```
 * Store the output JSON as the value of a GitHub secret named 'AZURE_CREDENTIALS'
   + Under your repository name, click Settings. 
   + In the "Security" section of the sidebar, select Secrets. 
   + At the top of the page, click New repository secret
   + Provide the secret name as AZURE_CREDENTIALS
   + Add the output JSON as secret value

### GitHub Workflow setup
1. Change the value of DEPLOYMENT_NAME and DEPLOYMENT_REGION in the deploy-JavaAKSBicep.yml workflow file under .github/workflows. 
   * The value for DEPLOYMENT_NAME should be globally unique, e.g. yournamedemo1
   * Use only lowercase letters and numbers for DEPLOYMENT_NAME. 
   * DEPLOYMENT_REGION should contain an Azure region name, e.g. eastus, westus, southus...etc...
2. Run the workflow 
   * If workflows are enabled for this repository it should run automatically. To enable the workflow run automatically, Go to Actions and enable the workflow if needed.
   * Workflow can be manually run 
     + Under your repository name, click Actions .
     + In the left sidebar, click the workflow "Build and Deploy Application".
     + Above the list of workflow runs, select Run workflow .
     + Use the Branch dropdown to select the workflow's main branch, Click Run workflow .
  

# Pet Clinic Website

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">


Congratulations! Now you have your containerized Java Sping Boot App deployed on AKS with supported JDK pushed to your ACR. 

# Pet Clinic Website - IP Address 

To view the deployed PetClinic app, follow the steps listed below:

1.  Go to GitHub Actions and click on your latest Deployment
2.  Scroll down to the section titled "Azure Powershell Cli - Get deployment IP Address"
3.  Open the Section....you will see a table, that list the EXTERNAL-IP.
4.  The EXTERNAL-IP will relfect the location of the deployment.  
5.  You can utilze the EXTERNAL-IP to view the deployed image. 

## Clean up resources
When you are done, you can delete all the Azure resources created with this template by running the following command:

```
resourceGroup=petclinicaks-rg
az group delete --name $resourceGroup
```
