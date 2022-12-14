echo "Cleaning up resources..."
echo
RG="trusted-ai"
az group delete --name $RG
echo "Resources cleaned up successfully"
echo