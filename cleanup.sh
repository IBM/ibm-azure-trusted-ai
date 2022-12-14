echo "\033[1;34mCleaning up resources...\n\033[0m"
RG="trusted-ai"
az group delete --name $RG
echo "\033[1;34mResources cleaned up successfully\n\033[0m"