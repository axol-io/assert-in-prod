#!/bin/bash

# Inspect the Kurtosis enclave
output=$(kurtosis enclave inspect my-testnet)

# Extract relevant information
services=$(echo "$output" | awk '/User Services/,/Search results:/ {if(NR>4) print $0}')

# Prepare an array to hold service details
declare -a service_details

# Loop through each service entry
while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Extract UUID, Name, and Ports
    uuid=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    ports=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf $i " "; print ""}' | sed 's/ *$//')  # Join all remaining fields as ports

    # Format the output for Assertor
    service_details+=("{\"uuid\": \"$uuid\", \"name\": \"$name\", \"ports\": \"$ports\"}")
done <<< "$services"

# Print the extracted service details in JSON format for Assertor
echo "[${service_details[*]}]"
