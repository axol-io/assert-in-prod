import http from 'k6/http';
import { check, sleep } from 'k6';

// Define the execution and consensus URLs
const executionUrl = 'http://127.0.0.1:32773'; // Replace with your actual execution URL
const consensusUrl = 'http://127.0.0.1:32786'; // Replace with your actual consensus URL

// Function to send JSON-RPC requests
function sendRpcRequest(url, method, params = []) {
    const payload = JSON.stringify({
        jsonrpc: "2.0",
        method: method,
        params: params,
        id: 1,
    });

    const res = http.post(url, payload, {
        headers: { 'Content-Type': 'application/json' },
    });

    return res;
}

export default function () {
    // Check execution node sync status
    let execRes = sendRpcRequest(executionUrl, 'eth_syncing');
    check(execRes, {
        'Execution service is up': (r) => r.status === 200,
        'Execution node is synced': (r) => r.json().result === false, // false means synced
    });

    // Check current block number from execution node
    let blockRes = sendRpcRequest(executionUrl, 'eth_blockNumber');
    check(blockRes, {
        'Block number retrieved successfully': (r) => r.status === 200,
        'Block number is a valid hex string': (r) => /^0x[0-9a-fA-F]+$/.test(r.json().result),
    });

    // Check consensus node sync status using health endpoint
    let consHealthRes = http.get(`${consensusUrl}/eth/v1/node/syncing`); // Adjust according to your consensus client
    check(consHealthRes, {
        'Consensus service is up': (r) => r.status === 200,
        'Consensus node is synced': (r) => JSON.parse(r.body).is_syncing === false, // Adjust based on actual response structure
    });

    // Check sync status
    let syncRes = http.get(`${consensusUrl}/lighthouse/syncing`, { headers: { 'accept': 'application/json' } });
    check(syncRes, {
        'Syncing endpoint is up': (r) => r.status === 200,
        'Node is synced': (r) => JSON.parse(r.body).SyncingFinalized === false, // Check if syncing is finalized
    });

    // Check connected peers
    let peersRes = http.get(`${consensusUrl}/lighthouse/peers/connected`, { headers: { 'accept': 'application/json' } });
    check(peersRes, {
        'Peers endpoint is up': (r) => r.status === 200,
        'Connected peers retrieved': (r) => Array.isArray(JSON.parse(r.body)) && JSON.parse(r.body).length > 0,
    });

    // Check validator metrics for a specific validator index
    const validatorIndex = 12345; // Replace with the actual validator index you're interested in
    let metricsRes = http.post(`${consensusUrl}/lighthouse/ui/validator_metrics`, JSON.stringify({ indices: [validatorIndex] }), {
        headers: { 'Content-Type': 'application/json' },
    });
    check(metricsRes, {
        'Validator metrics endpoint is up': (r) => r.status === 200,
        'Validator metrics retrieved successfully': (r) => JSON.parse(r.body).attestation_hits !== undefined,
    });

    // Check health status
    let healthRes = http.get(`${consensusUrl}/lighthouse/health`, { headers: { 'accept': 'application/json' } });
    check(healthRes, {
        'Health endpoint is up': (r) => r.status === 200,
        'Health status is ok': (r) => JSON.parse(r.body).status === 'ok', // Adjust based on actual response structure
    });

    sleep(1); // Pause for a second between iterations
}