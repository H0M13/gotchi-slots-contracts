const networkConfig = {
    default: {
        name: 'hardhat',
        fee: '100000000000000000',
        keyHash: '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4',
        jobId: '29fa9aa13bf1468788b7cc4a500a45b8',
        fundAmount: "1000000000000000000"
    },
    31337: {
        name: 'localhost',
        fee: '100000000000000000',
        keyHash: '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4',
        jobId: '29fa9aa13bf1468788b7cc4a500a45b8',
        fundAmount: "1000000000000000000"
    },
    80001: {
        name: 'mumbai',
        linkToken: '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
        vrfCoordinator: '0x8C7382F9D8f56b33781fE506E897a4F1e2d17255',
        keyHash: '0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4',
        fee: '100000000000000',
        fundAmount: '1000000000000000'
    },
    137: {
        name: 'polygon',
        linkToken: '0xb0897686c545045aFc77CF20eC7A532E3120E0F1',
        vrfCoordinator: '0x3d2341ADb2D31f1c5530cDC622016af293177AE0',
        keyHash: '0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da',
        fee: '100000000000000',
        fundAmount: '1000000000000000'
    }
}

const developmentChains = ["hardhat", "localhost"]

const getNetworkIdFromName = async (networkIdName) => {
    for (const id in networkConfig) {
        if (networkConfig[id]['name'] == networkIdName) {
            return id
        }
    }
    return null
}

const autoFundCheck = async (contractAddr, networkName, linkTokenAddress, additionalMessage) => {
    const chainId = await getChainId()
    console.log("Checking to see if contract can be auto-funded with LINK:")
    const amount = networkConfig[chainId]['fundAmount']
    //check to see if user has enough LINK
    const accounts = await ethers.getSigners()
    const signer = accounts[0]
    const LinkToken = await ethers.getContractFactory("LinkToken")
    const linkTokenContract = new ethers.Contract(linkTokenAddress, LinkToken.interface, signer)
    const balanceHex = await linkTokenContract.balanceOf(signer.address)
    const balance = await web3.utils.toBN(balanceHex._hex).toString()
    const contractBalanceHex = await linkTokenContract.balanceOf(contractAddr)
    const contractBalance = await web3.utils.toBN(contractBalanceHex._hex).toString()
    if (balance > amount && amount > 0 && contractBalance < amount) {
        //user has enough LINK to auto-fund
        //and the contract isn't already funded
        return true
    } else { //user doesn't have enough LINK, print a warning
        console.log("Account doesn't have enough LINK to fund contracts, or you're deploying to a network where auto funding isnt' done by default")
        console.log("Please obtain LINK via the faucet at https://" + networkName + ".chain.link/, then run the following command to fund contract with LINK:")
        console.log("npx hardhat fund-link --contract " + contractAddr + " --network " + networkName + additionalMessage)
        return false
    }
}

module.exports = {
    networkConfig,
    getNetworkIdFromName,
    autoFundCheck,
    developmentChains
}
