/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
require("@nomiclabs/hardhat-truffle5")
require("@nomiclabs/hardhat-etherscan")
require("@appliedblockchain/chainlink-plugins-random-number-consumer")
require("hardhat-deploy")
require("./tasks/accounts")
require("./tasks/balance")
require("./tasks/fund-link")
require("./tasks/withdraw-link")
require("./tasks/block-number")


require('dotenv').config()

const POLYGON_MAINNET_RPC_URL = process.env.POLYGON_MAINNET_RPC_URL
const MUMBAI_TESTNET_RPC_URL = process.env.MUMBAI_TESTNET_RPC_URL
const MNEMONIC = process.env.MNEMONIC || "your mnemonic"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "Your etherscan API key"
// optional
const PRIVATE_KEY = process.env.PRIVATE_KEY || "your private key"

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
        },
        localhost: {
        },
        polygon: {
            url: POLYGON_MAINNET_RPC_URL,
            accounts: {
                mnemonic: MNEMONIC,
            },
            saveDeployments: true,
        },
        mumbai: {
            url: MUMBAI_TESTNET_RPC_URL,
            accounts: {
                mnemonic: MNEMONIC,
            },
            saveDeployments: true,
        },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: ETHERSCAN_API_KEY
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0 // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        feeCollector: {
            default: 1
        }
    },
    solidity: {
        compilers: [
            {
                version: "0.6.6"
            },
            {
                version: "0.4.24"
            }
        ]
    },
    mocha: {
        timeout: 100000
    }
}

