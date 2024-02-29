-include .env

# deps
update:; forge update
build  :; forge build
size  :; forge build --sizes

# storage inspection
inspect :; forge inspect ${contract} storage-layout --pretty

test = test_no_loss_game_w_transfers

FORK_URL := ${ARBI_RPC_URL} 

# local tests without fork
test  :; forge test -vv --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
trace  :; forge test -vvv --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
gas  :; forge test --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} --gas-report
test-contract  :; forge test -vv --match-contract $(contract) --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
test-contract-gas  :; forge test --gas-report --match-contract ${contract} --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
trace-contract  :; forge test -vvv --match-contract $(contract) --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
test-test  :; forge test -vv --match-test $(test) --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
trace-test  :; forge test -vvv --match-test $(test) --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
snapshot :; forge snapshot -vv --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}
snapshot-diff :; forge snapshot --diff -vv --fork-url ${FORK_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy :; forge script --etherscan-api-key ${ETHERSCAN_API_KEY}  --rpc-url $(TESTNET_RPC_URL) --network $(TESTNET_NETWORK) --keystore ~/.foundry/keystores/DEPLOYER --sender 0xfA4EB9AA068B3b64348f42b142E270f28E2f86EB --verify --chain-id 421614

clean  :; forge clean
