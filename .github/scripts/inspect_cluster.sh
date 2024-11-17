#!/bin/bash

# Inspect the Kurtosis enclave and capture the output
output=$(kurtosis enclave inspect my-testnet)

# Check if the command succeeded
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to inspect the enclave 'my-testnet'."
    exit 1
fi

# Prepare an array to hold endpoint configurations
declare -a endpoints

# Extract the "User Services" section from the output
services_section=$(echo "$output" | awk '/User Services:/,0' | sed '1d')

# Debugging: Output the services section for inspection
echo "Services section extracted:"
echo "$services_section"

# Loop through each line in the services section
while IFS= read -r line; do
    # Skip empty or invalid lines
    [[ -z "$line" || "$line" =~ ^Search\ results: ]] && continue

    # Debugging: Output each line being processed
    echo "Processing line: $line"

    # Extract UUID, Name, and Ports using awk
    uuid=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    ports=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf $i " "; print ""}' | sed 's/ *$//')

    # Debugging: Output the extracted UUID, Name, and Ports
    echo "UUID: $uuid"
    echo "Name: $name"
    echo "Ports: $ports"

    # Check if the service is related to an execution client (e.g., Geth, Lodestar, Prysm)
    if [[ "$name" == *"geth"* || "$name" == *"lodestar"* || "$name" == *"prysm"* ]]; then
        # Extract RPC and Metrics ports using regex
        rpc_port=$(echo "$ports" | grep -oP 'rpc: \K[0-9]+' | head -1)
        metrics_port=$(echo "$ports" | grep -oP 'metrics: \K[0-9]+' | head -1)

        # Debugging: Output the extracted RPC and Metrics ports
        echo "RPC Port: $rpc_port"
        echo "Metrics Port: $metrics_port"

        # Check if both RPC and Metrics ports are found
        if [[ -n "$rpc_port" && -n "$metrics_port" ]]; then
            # Construct the endpoint JSON object and add it to the array
            endpoints+=("{\"name\": \"$name\", \"executionUrl\": \"http://localhost:$rpc_port\", \"consensusUrl\": \"http://localhost:$metrics_port\"}")
        fi
    fi
done <<< "$services_section"

# Print the array in a usable format
echo "Endpoints array:"
for endpoint in "${endpoints[@]}"; do
    echo "$endpoint"
done

# If you want to return the array to be used later in the script:
# You can access the array like this:
# for endpoint in "${endpoints[@]}"; do
#   echo "$endpoint"
# done

