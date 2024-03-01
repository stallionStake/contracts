# Smart Contracts for Stallion Stake ETH Denver Submission 

This repo will allow you to write, test and deploy Stallion Stake Smart Contracts" using [Foundry](https://book.getfoundry.sh/).

For a more complete overview of how the Stallion Stake Contracts work please visit the [Stallion Stake Slides](https://github.com/yearn/tokenized-strategy).

## How to start

### Requirements

First you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation).
NOTE: If you are on a windows machine it is recommended to use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

### Fork this repository

```sh
git clone --recursive https://github.com/user/tokenized-strategy-foundry-mix

cd tokenized-strategy-foundry-mix

yarn
```

### Set your environment Variables

Sign up for [Infura](https://infura.io/) and generate an API key and copy your RPC url. Store it in the `ETH_RPC_URL` environment variable.
NOTE: you can use other services.

Use .env file

1. Make a copy of `.env.example`
2. Add the values for `ETH_RPC_URL`, `ETHERSCAN_API_KEY` and other example vars
     NOTE: If you set up a global environment variable, that will take precedence.

### Build the project

```sh
make build
```

Run tests

```sh
make test
```

## Contracts

Stallion Stake uses the following contracts

Fantasy Factory - a permissionless smart contract where any new Fantasy games can be created. For new games users simply need to specify paramaters for length of competition (in days), entry cost, if loss or no loss & the underlying ERC4626 vault used to earn yield on locked funds

Fantasy Oracle - a smart contract which stores a mapping of player ID & date (each date has a unique uint256 value using UNIX timestamp provided by block.timestamp / seconds per day) mapped to actual live Fantasy scores 

Fantasy Game - any time new games are created via the Fantasy Factory a new game contract is deployed. Players can enter compeitions by providing their picks (an array of 5 uint256 values for the appropriate player ID's). When entering competitions players funds are transferred into the Game contract and deposited directly into the underlying vault chosen while also minting a unique NFT representing their entry. At the end of the game this NFT can be burned to claim winning prize (and also claim back funds in No Loss games). 

## Testing

Tests run in fork environment, you need to complete the full installation and setup to be able to run these commands.

```sh
make test
```

Run tests with traces (very useful)

```sh
make trace
```

Run specific test contract (e.g. `test/StrategyOperation.t.sol`)

```sh
make test-contract contract=StrategyOperationsTest
```

Run specific test contract with traces (e.g. `test/StrategyOperation.t.sol`)

```sh
make trace-contract contract=StrategyOperationsTest
```


To enable test workflow you need to add `ETHERSCAN_API_KEY` and `ETH_RPC_URL` secrets to your repo. For more info see [GitHub Actions docs](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-a-repository).

If the slither finds some issues that you want to suppress, before the issue add comment: `//slither-disable-next-line DETECTOR_NAME`. For more info about detectors see [Slither docs](https://github.com/crytic/slither/wiki/Detector-Documentation).
