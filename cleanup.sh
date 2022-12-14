echo "Cleaning up resources...\n"
RG="trusted-ai"
az group delete --name $RG
echo "Resources cleaned up successfully\n"