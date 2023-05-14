#!/bin/bash

get_wallet_address(){
    cd $HOME/celestia-node/
    response=$(./cel-key list --node.type light --keyring-backend test --p2p.network blockspacerace)
    address=$(echo "$response" | grep -oP '(?<=- address: )[^\s]+')
    echo "Wallet address : $address"
}

get_node_id(){
    echo "Getting Auth token..."
    NODE_TYPE=light
    AUTH_TOKEN=$(celestia $NODE_TYPE auth admin --p2p.network blockspacerace)

    response=$(curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658)

    ID=$(echo "$response" | jq -r '.result.ID')
    echo "Node ID: $ID"
}

get_wallet_balance() {
    echo "Getting wallet balance..."
    response=$(curl -s -X GET http://127.0.0.1:26659/balance)
    amount=$(echo "$response" | jq -r '.amount')
    denom=$(echo "$response" | jq -r '.denom')
    echo "The wallet got $amount $denom"
}

get_block_header() {
    echo "Getting block header..."
    curl -X GET http://127.0.0.1:26659/header/1
}

submit_pfb_transaction() {
    echo "Submitting a PFB transaction..."

    echo "Generating namespace_id..."
    namespace_id=$(generate_namespaceId)
    echo "namespace_id : " $namespace_id

    echo "Generating random data..."
    data=$(generate_data)
    echo "data : " $data

    echo "Sending PFB..."

    response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"namespace_id\": \"$namespace_id\", \"data\": \"$data\", \"gas_limit\": 80000, \"fee\": 2000}" http://localhost:26659/submit_pfb)
 
	# We do not use jq here has the returned json is generating an mal formated error with jq
    height=$(echo "$response" | grep -oP '(?<="height":)\d+')
    txhash=$(echo "$response" | grep -oP '(?<="txhash":")[^"]+')

	#height=$(echo "$response" | jq -r '.height')
	#txhash=$(echo "$response" | jq -r '.txhash')

    echo "The PFB returned height : $height"
    echo "The associated txhash : $txhash"
    sleep 7
    echo "Getting Shares..."
    response=$(curl -X GET http://localhost:26659/namespaced_shares/$namespace_id/height/$height)
    #echo "response: $response"
    #shares=$(echo $response | grep -oP '(?<="shares":\[").*?(?="])' | tr -d '"')
    shares=$(echo "$response" | jq -r '.shares[0]')
    echo "Shares : $shares"
}

generate_namespaceId() {
random_value=$(od -An -N8 -tx8 /dev/urandom | tr -d ' ')
    namespace_id=$(printf "%016x" "0x$random_value")
    echo $namespace_id
}

generate_data() {
    length=$((10 + RANDOM % 128))
    random_message=$(xxd -l $length -p /dev/urandom)
    echo $random_message
}



while true; do

echo "--------------------------------------------------------------------------------------------"
echo "|                              CELESTIA LIGHT NODE TOOLS                                   |"
echo "--------------------------------------------------------------------------------------------"
echo "| This toolbox will help you to execute and interact easyly with your Celestia Light Node |"
echo "| The node will be used on http://localhost:26659, please update the script if necessary   |"
echo "[                          -----------------------------------                             |"
echo "| Please select an option:                                                                 |"
echo "| 1. Get Wallet address                                                                    |"
echo "| 2. Get Node ID                                                                           |"
echo "| 3. Get wallet balance                                                                    |"
echo "| 4. Get actual block header                                                               |"
echo "| 5. Submit a PFB transaction                                                              |"
echo "| X. Quit                                                                                  |"
echo "--------------------------------------------------------------------------------------------"

read -p "Enter your choice: " choice

case $choice in
    1)
        get_wallet_address
        ;;
    2)
        get_node_id
        ;;
    3)
        get_wallet_balance
        ;;
    4)
        get_block_header
        ;;
    5)
        submit_pfb_transaction
        ;;
    X)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please enter a number between 1 and 5."
        exit 1
        ;;
esac
done


