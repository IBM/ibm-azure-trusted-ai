#!/usr/bin/env bash

set -e

echo "Setting up Trusted AI demo on TechZone..."
echo "********************"
az extension add -n account --only-show-errors > logs.txt
SUBSCRIPTIONID=$(az account subscription list --only-show-errors | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['subscriptionId'])")
echo "********************"
echo "Subscription ID:" 
echo $SUBSCRIPTIONID
echo "********************"

RG="trusted-ai"
echo "Resource Group:"
echo $RG
echo "********************"

# 1. Deploy Resource Group Template
STEP1="Step 1: Creating Resource Group 'trusted-ai'..."
echo $STEP1
echo
echo "For installation details, check 'logs.txt' file..."
echo
echo $STEP1 >> logs.txt
az deployment create \
--template-file azure-rg/template.json \
--parameters azure-rg/parameters.json \
--location EastUS --only-show-errors >> logs.txt

echo "Successfully created resource group"
echo "********************"

# 2. Deploy Azure ML Template
STEP2="Step 2: Deploying Azure Machine Learning resources..."
echo $STEP2
echo
echo "For installation details, check 'logs.txt' file..."
echo
echo $STEP2 >> logs.txt
az deployment group create \
--resource-group $RG \
--template-file azure-ml/template.json \
--parameters azure-ml/parameters.json --only-show-errors >> logs.txt
echo "Successfully created Azure Machine Learning workspace 'trusted-ai-dev'"
echo "********************"

# 3. Add Azure ML plugin to AZ CLI
STEP3="Step 3: Setting up Azure ML CLI..."
echo $STEP3
echo
echo "For installation details, check 'logs.txt' file..."
echo
echo $STEP3 >> logs.txt
az extension remove -n ml --only-show-errors >> logs.txt
az extension add -n azure-cli-ml --only-show-errors >> logs.txt
echo "Successfully setup Azure ML CLI"
echo "********************"

# 4. Deploy Azure ML Compute Instance (Standard A1_V2)
STEP4="Step 4: Deploying Azure ML Compute Instance..."
echo $STEP4
echo
echo "For installation details, check 'logs.txt' file..."
echo
echo $STEP4 >> logs.txt
az ml computetarget create computeinstance  -n techzone -s "STANDARD_A1_V2" -v -w trusted-ai-dev -g $RG --only-show-errors >> logs.txt
echo "Successfully created Azure ML Compute Instance 'techzone'."
echo "********************"

# 5. Upload Notebooks to the File Share
STEP5="Step 5: Uploading Notebooks to Azure File Share..."
echo $STEP5
echo
echo $STEP5 >> logs.txt
STORAGEACCOUNT=$(az storage account list -g $RG --only-show-errors | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['name'])")
FILESHARE=$(az storage share list --account-name $STORAGEACCOUNT --only-show-errors | python3 -c "import sys, json; print(json.load(sys.stdin)[1]['name'])")
STORAGEACCOUNTKEY=$(az storage account keys list -g $RG -n $STORAGEACCOUNT --only-show-errors | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['value'])")
echo
echo "For installation details, check 'logs.txt' file..."
echo
az storage file upload --account-name $STORAGEACCOUNT --account-key $STORAGEACCOUNTKEY --share-name $FILESHARE --path Credit-risk-model.ipynb --source notebooks/Credit-risk-model.ipynb --only-show-errors >> logs.txt
az storage file upload --account-name $STORAGEACCOUNT --account-key $STORAGEACCOUNTKEY --share-name $FILESHARE --path Drift-Detection-model.ipynb --source notebooks/Drift-Detection-model.ipynb --only-show-errors >> logs.txt
echo "Successfully uploaded the notebooks"
echo "********************"

# 7. Create a service principal
STEP6="Step 6: Creating service principal..."
echo $STEP6
echo
echo $STEP6 >> logs.txt
echo
echo "For installation details, check 'logs.txt' file..."
echo
az ad sp create-for-rbac --name creds-for-openscale --role contributor --scopes /subscriptions/$SUBSCRIPTIONID/resourceGroups/$RG --only-show-errors > azuremlcredentials.json
python3 -c "import json; f=open('azuremlcredentials.json'); j = json.load(f); j['subscriptionid'] = '"${SUBSCRIPTIONID}"'; f.close(); f=open('azuremlcredentials.json','w', encoding='utf-8'); json.dump(j,f, ensure_ascii=False, indent=2); f.close()"
az storage file upload --account-name $STORAGEACCOUNT --account-key $STORAGEACCOUNTKEY --share-name $FILESHARE --path azuremlcredentials.json --source azuremlcredentials.json --only-show-errors >> logs.txt
echo "Successfully created Azure service principal and uploaded the credentials to Azure File Share"
echo "********************"


echo "Setup completed. Launch Azure ML Studio by visiting the link: https://ml.azure.com"
echo