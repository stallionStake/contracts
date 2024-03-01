# Smart Contracts for Stallion Stake (ETH Denver Submission)

This repo will allow you to write, test and deploy Stallion Stake Smart Contracts" using [Foundry](https://book.getfoundry.sh/).

For a more complete overview of how the Stallion Stake works please visit the [Stallion Stake Slides]([https://github.com/yearn/tokenized-strategy](https://docs.google.com/presentation/d/1Cz48o3uYA6nUBVLMnmr4oExCU24gNNIH3uHKtMPKwgY/edit?usp=sharing)).

### Stallion Stake Flow 

1. New games created via Factory contract -> users can specify start date, game duration, underlying ERC4626 used to earn yield on assets, entry cost & if game is no-loss or not
2. Users enter game via newly created game contract via Factory when entering game the following happens
   - Check picks are valid & entry is before submission deadline 
   - Transfers ERC20 entry cost from user & deposits directly to vault
   - Maps users picks to entry ID
   - Mints ERC721 to user tracking their entry (this allows users to potentially transfer / sell entries mid game on secondary market) 
  
3. Upon completion of game - Game calls oracle to calculate scores of players & determine winner
4. Once game is completed users can burn NFT's to claim winning (& also entry cost for losers if no loss game) 
  
## How to start

### Requirements

First you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation).
NOTE: If you are on a windows machine it is recommended to use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
Once installed you can clone this repository and compile contracts & run relevant tests 

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

### FantasyFactory.sol
a permissionless smart contract where any new Fantasy games can be created. For new games users simply need to specify paramaters for length of competition (in days), entry cost, if loss or no loss & the underlying ERC4626 vault used to earn yield on locked funds

(Additionally the Factory has been deployed on Arbitrum Sepolia : https://sepolia.arbiscan.io/address/0xEc2638E834848717bd991BC2c5FBDd9C19EEf5Be#code ) 

### FantasyOracle.sol
A smart contract which stores a mapping of player ID & date (each date has a unique uint256 value using UNIX timestamp provided by block.timestamp / seconds per day) mapped to actual live Fantasy scores 

(Additionally the Oracle has been deployed on Arbitrum Sepolia : https://sepolia.arbiscan.io/address/0xEc2638E834848717bd991BC2c5FBDd9C19EEf5Be#code ) 

### FantasyGame.sol 
Any time new games are created via the Fantasy Factory a new game contract is deployed. Players can enter compeitions by providing their picks (an array of 5 uint256 values for the appropriate player ID's). When entering competitions players funds are transferred into the Game contract and deposited directly into the underlying vault chosen while also minting a unique NFT representing their entry. At the end of the game this NFT can be burned to claim winning prize (and also claim back funds in No Loss games). 

## Additional Contracts (EVC) 

Additionally as we have used ERC721 to represent entries into Stallion Stake games we have developed a modified Vault roughly following the EVC / ERC4626 standard which can be connected to [EVC](https://evc.wtf/) the contracts for this are listed below. 

### VaultSimpleERC721.sol 
This contract follows the pattern used in [Eulers EVC playground](https://github.com/euler-xyz/evc-playground) for their OZ Vault Simple implementation with slight modifications to be compatible with ERC721 primarily by instead minting ERC20 token representing deposits a new ERC721 is minted which maps directly to the underlying ERC721 token id 

### VaultERC721Borrowable.sol 
This contract builds on top of the above contract and adds basic borrowing functionality allowing users to use other collaterals via the EVC to borrow ERC721's which have been deposited. This contract roughly follows the VaultRegularBorrowable.sol exmample in the EVC playground however for simplicity we have ommitted interest rates & assumed users can borrow at 0% rates to reduce complexity for this simplified example.  

## Periphery Contracts

### Strategy.sol
We have utilised Yearn V3 code base in order to mimick an ERC4626 contract being used in games. 

## Testing

Tests run in fork environment, you need to complete the full installation and setup to be able to run these commands.

```sh
make test
```

Run tests with traces (very useful)

```sh
make trace
```

Note the primary flow of the Stallion Stake Games are tested in the file NewGame.t.sol 

These tests run through the following scenarios 
1. test_new_game : Users playing full game (not in no loss) with user claiming full prize pool at end of game in 
2. test_no_loss_game : Users playing no loss game with yield generated on vault (utilising Yearn V3 architecture to mimic ERC4626 vault) & winner claiming yield while user claims back loss
3. test_no_loss_game_w_transfers : Users playing no loss game with users transferring their ERC721 representing their entry mid game & new ERC721 claiming winning / losses back at the end of the game. 

Run specific test contract (e.g. `test/NewGame.t.sol`)

```sh
make test-contract contract=NewGame
```


To enable test workflow you need to add `ETHERSCAN_API_KEY` and `ETH_RPC_URL` secrets to your repo. For more info see [GitHub Actions docs](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-a-repository).

If the slither finds some issues that you want to suppress, before the issue add comment: `//slither-disable-next-line DETECTOR_NAME`. For more info about detectors see [Slither docs](https://github.com/crytic/slither/wiki/Detector-Documentation).
