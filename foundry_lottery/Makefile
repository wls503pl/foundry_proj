-include .env

.PHONY: all test deploy

build :; forge build

test :
	forge test

coverage :
	forge coverage

install :; forge install cyfrin/foundry-devops@0.4.0 && \
	forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && \
	forge install foundry-rs/forge-std@v1.9.6 && forge install transmission11/solmate@v6

deploy-sepolia :; forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) \
	--account myAccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)