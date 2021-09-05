# Contracts for ['1 Arm Baandit' minigame](https://github.com/H0M13/gotchi-slots)

This repo began as the [Chainlink Hardhat Box](https://github.com/smartcontractkit/hardhat-starter-kit)

 ## Requirements

- [NPM](https://www.npmjs.com/) or [YARN](https://yarnpkg.com/)

## Installation

Set your `POLYGON_MAINNET_RPC_URL` and `MUMBAI_TESTNET_RPC_URL` [environment variable.](https://www.twilio.com/blog/2017/01/how-to-set-environment-variables.html). You can get them for free at [Infura's site.](https://infura.io/) You'll also need to set the variable `MNEMONIC` which is your mnemonic from your wallet, ie MetaMask. This is needed for deploying contracts to public networks. You can optionally set your `PRIVATE_KEY` instead with some changes to the `hardhat.config.js`.

You can set these in your `.env` file if you're unfamiliar with how setting environment variables work. Check out our [.env example](https://github.com/smartcontractkit/hardhat-starter-kit/blob/main/.env.example). If you wish to use this method to set these variables, update the values in the .env.example file, and then rename it to '.env'

![WARNING](https://via.placeholder.com/15/f03c15/000000?text=+) **WARNING** ![WARNING](https://via.placeholder.com/15/f03c15/000000?text=+)

Don't commit and push any changes to .env files that may contain sensitive information, such as a private key! If this information reaches a public GitHub repository, someone can use it to check if you have any Mainnet funds in that wallet address, and steal them!

`.env` example:
```
POLYGON_MAINNET_RPC_URL='www.infura.io/asdfadsfafdadf'
MUMBAI_TESTNET_RPC_URL='www.infura.io/asdfadsfafdadf'
MNEMONIC='cat dog frog...'
```
`bash` example
```
export POLYGON_MAINNET_RPC_URL='www.infura.io/asdfadsfafdadf'
export MUMBAI_TESTNET_RPC_URL='www.infura.io/asdfadsfafdadf'
export MNEMONIC='cat dog frog...'
```

Then you can install all the dependencies

```bash
git clone https://github.com/smartcontractkit/hardhat-starter-kit/
cd hardhat-starter-kit
```
then

```bash
npm install
```

Or

```bash
yarn
```


## Auto-Funding

This Starter Kit is configured by default to attempt to auto-fund any newly deployed contract that uses Any-API or Chainlink VRF, to save having to manually fund them after each deployment. The amount in LINK to send as part of this process can be modified in the [Starter Kit Config](https://github.com/smartcontractkit/chainlink-hardhat-box/blob/main/helper-hardhat-config.js), and are configurable per network.

| Parameter  | Description                                       | Default Value |
| ---------- | :------------------------------------------------ | :------------ |
| fundAmount | Amount of LINK to transfer when funding contracts | 1 LINK        |

If you wish to deploy the smart contracts without performing the auto-funding, run the following command when doing your deployment:

```bash
npx hardhat deploy --tags main
```


## Deploy

Deployment scripts are in the [deploy](https://github.com/smartcontractkit/hardhat-starter-kit/tree/main/deploy) directory. If required, edit the desired environment specific variables or constructor parameters in each script, then run the hardhat deployment plugin as follows.

This will deploy to a local hardhat network

```bash
npx hardhat deploy
```

To deploy to testnet:
```bash
npx hardhat deploy --network mumbai
```

## Test
Tests are located in the [test](https://github.com/smartcontractkit/hardhat-starter-kit/tree/main/test) directory, and are split between unit tests and integration tests. Unit tests should only be run on local environments, and integration tests should only run on live environments.

To run unit tests:

```bash
yarn test
```

To run integration tests:

```bash
yarn test-integration
```

## Run

The deployment output will give you the contract addresses as they are deployed. You can then use these contract addresses in conjunction with Hardhat tasks to perform operations on each contract

### VRF Get a random number
The VRFConsumer contract has two tasks, one to request a random number, and one to read the result of the random number request. This contract needs to be funded with link first:

```bash
npx hardhat fund-link --contract insert-contract-address-here --network network
```

Once it's funded, you can perform a VRF request with the request-random-number task:

```bash
npx hardhat request-random-number --contract insert-contract-address-here --network network
```

Once you have successfully made a request for a random number, you can see the result via the read-random-number task:

```bash
npx hardhat read-random-number --contract insert-contract-address-here --network network
```

### Linting

```
yarn lint:fix
```
