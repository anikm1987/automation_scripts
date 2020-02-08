#!/bin/bash
# Testing error handling for AZURE commands inside of bash

read_properties()
{
  file=$1
  while IFS="=" read -r key value; do
    case "$key" in
      "clientID") clientID="$value" ;;
      "secret") secret="$value" ;;
      "tenantID") tenantID="$value" ;;
      "subscriptionID") subscriptionID="$value" ;;     
    esac
  done < "$file"
}    

read_properties credential.info

echo "tenantID            : $tenantID"
echo "clientID            : $clientID"
echo "secret              : *********"
echo "subscriptionID      : $subscriptionID"

az cloud set --name AzureCloud

az login --service-principal --username $clientID --password $secret --tenant $tenantID
az account set -s $subscriptionID
if [ ${?} -eq 0 ]; then
  echo "Subscription set"
else
  echo "ERROR: Subscription set"
  exit 1 # wrong args
fi

echo "Connected to Azure"