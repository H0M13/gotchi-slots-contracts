pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IAavegotchiFacet} from "./Aavegotchi/interfaces/IAavegotchiFacet.sol";
import {ICollateralFacet} from "./Aavegotchi/interfaces/ICollateralFacet.sol";

contract RandomNumberConsumer is VRFConsumerBase, Ownable {

    bytes32 public keyHash;
    uint256 public fee;
    address public vrfCoordinator;
    address public link;

    uint public AMOUNT_PER_10_SPINS = 10 ether;
    int256 public reserves = 1000 ether;
    // 18 decimal places
    uint256 public jackpotAmount = 200 ether;

    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => uint256) public requestIdToGotchiId;
    mapping(bytes32 => uint256) public requestIdToRandomNumber;
    mapping(bytes32 => bool) public requestIdToProcessedBool;
    mapping(address => bool) public addressToClaimedFakeTokensBool;

    mapping(address => uint256) public addressToFakeTokens;

    mapping(address => uint256) public collateralAddressToType;

    address public aavegotchiDiamondAddress = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;

    IAavegotchiFacet public immutable facet = IAavegotchiFacet(aavegotchiDiamondAddress);
    ICollateralFacet public immutable collateralFacet = ICollateralFacet(aavegotchiDiamondAddress);

    mapping(bytes32 => uint256[10]) public requestIdToSpinOutcomes;

    event RequestedRandomness(bytes32 requestId);
    event RandomnessReceived(bytes32 requestId, address requestAddress, uint256 randomResult);
    event SpinsCalculated(bytes32 requestId, address player);

    function linkBalance() external view returns (uint256 linkBalance_) {
        linkBalance_ = LINK.balanceOf(address(this));
    }

    constructor(address _vrfCoordinator,
                address _link,
                bytes32 _keyHash,
                uint _fee)
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        keyHash = _keyHash;
        fee = _fee;
        link = _link;
        vrfCoordinator = _vrfCoordinator;
        collateralAddressToType[0xE0b22E0037B130A9F56bBb537684E6fA18192341] = 1; // maDAI
        collateralAddressToType[0x27F8D03b3a2196956ED754baDc28D73be8830A6e] = 1; // amDAI
        collateralAddressToType[0x20D3922b4a1A8560E1aC99FBA4faDe0c849e2142] = 2; // maWETH
        collateralAddressToType[0x28424507fefb6f7f8E9D3860F56504E4e5f5f390] = 2; // amWETH
        collateralAddressToType[0x823CD4264C1b951C9209aD0DeAea9988fE8429bF] = 3; // maAAVE
        collateralAddressToType[0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360] = 3; // amAAVE
        collateralAddressToType[0x98ea609569bD25119707451eF982b90E3eb719cD] = 4; // maLINK
        collateralAddressToType[0xDAE5F1590db13E3B40423B5b5c5fbf175515910b] = 5; // maUSDT
        collateralAddressToType[0x60D55F02A771d515e077c9C2403a1ef324885CeC] = 5; // amUSDT
        collateralAddressToType[0x9719d867A500Ef117cC201206B8ab51e794d3F82] = 6; // maUSDC
        collateralAddressToType[0x1a13F4Ca1d028320A707D99520AbFefca3998b7F] = 6; // amUSDC
        collateralAddressToType[0xF4b8888427b00d7caf21654408B7CBA2eCf4EbD9] = 7; // maTUSD
        collateralAddressToType[0x8c8bdBe9CeE455732525086264a4Bf9Cf821C498] = 8; // maUNI
        collateralAddressToType[0xe20f7d1f0eC39C4d5DB01f53554F2EF54c71f613] = 9; // maYFI
        collateralAddressToType[0x5c2ed810328349100A66B82b78a1791B101C9D61] = 10; // amWBTC
        collateralAddressToType[0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4] = 11; // amWMATIC
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber(uint256 gotchiId) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(facet.ownerOf(gotchiId) == msg.sender, "Sender doesn't own this aavegotchi");
        require(addressToFakeTokens[msg.sender] >= AMOUNT_PER_10_SPINS, "Not enough funds");

        addressToFakeTokens[msg.sender] -= AMOUNT_PER_10_SPINS;

        // Put 99.5% into reserves
        reserves += int256(AMOUNT_PER_10_SPINS * (0.995 ether));

        // Add .5% to jackpot
        jackpotAmount += AMOUNT_PER_10_SPINS * (0.005 ether);

        requestId = requestRandomness(keyHash, fee);

        requestIdToAddress[requestId] = msg.sender;
        requestIdToGotchiId[requestId] = gotchiId;

        emit RequestedRandomness(requestId);
    }

    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address requestAddress = requestIdToAddress[requestId];
        requestIdToRandomNumber[requestId] = randomness;
        
        emit RandomnessReceived(requestId, requestAddress, randomness);
    }

    function processRandomNumber(bytes32 requestId) public {
        require(requestIdToProcessedBool[requestId] == false, "RequestId already processed");

        requestIdToProcessedBool[requestId] = true;

        uint256 usedGotchiId = requestIdToGotchiId[requestId];

        uint256 collateralType = getCollateralType(usedGotchiId);

        // Stablecoins group
        if (collateralType == 1 || collateralType == 5 || collateralType == 6 || collateralType == 7) {
            ProcessOdds(requestId,58349,83349,95849,99149,99849,99999);
        }
        // ETH or BTC
        else if (collateralType == 2 || collateralType == 10) {
            ProcessOdds(requestId,62899,85399,95899,98999,99799,99999);
        }
        // MATIC or UNI
        else if (collateralType == 11 || collateralType == 8) {
            ProcessOdds(requestId,67749,86849,96049,98849,99749,99999);
        }
        // LINK, YFI or AAVE
        else if (collateralType == 3 || collateralType == 4 || collateralType == 9) {
            ProcessOdds(requestId,72449,88449,96199,98699,99699,99999);
        }

        emit SpinsCalculated(requestId, requestIdToAddress[requestId]);
    }

    function ProcessOdds(bytes32 requestId, uint256 maxFor0, uint256 maxFor1, uint256 maxFor2, uint256 maxFor5, uint256 maxFor25, uint256 maxFor100) internal {
        uint256[] memory expandedValues = expand(requestIdToRandomNumber[requestId], 10);
        for (uint i=0; i<10; i++) {
            uint256 spinValue = (expandedValues[i] % 100000) + 1;
            if (spinValue <= maxFor0) {
                requestIdToSpinOutcomes[requestId][i] = 0 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 0 ether;
            } 
            else if (spinValue > maxFor0 && spinValue <= maxFor1) {
                requestIdToSpinOutcomes[requestId][i] = 1 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 1 ether;
                reserves -= 1 ether;
            }
            else if (spinValue > maxFor1 && spinValue <= maxFor2) {
                requestIdToSpinOutcomes[requestId][i] = 2 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 2 ether;
                reserves -= 2 ether;
            }
            else if (spinValue > maxFor2 && spinValue <= maxFor5) {
                requestIdToSpinOutcomes[requestId][i] = 5 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 5 ether;
                reserves -= 5 ether;
            }
            else if (spinValue > maxFor5 && spinValue <= maxFor25) {
                requestIdToSpinOutcomes[requestId][i] = 25 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 25 ether;
                reserves -= 25 ether;
            }
            else if (spinValue > maxFor25 && spinValue <= maxFor100) {
                requestIdToSpinOutcomes[requestId][i] = 100 ether;
                addressToFakeTokens[requestIdToAddress[requestId]] += 100 ether;
                reserves -= 100 ether;
            }
            else {
                // JACKPOT!!!
                requestIdToSpinOutcomes[requestId][i] = jackpotAmount;
                addressToFakeTokens[requestIdToAddress[requestId]] += jackpotAmount;
                jackpotAmount = 0;
            }
        }
    }

    function getCollateralAddress(uint256 gotchiId) external view returns (address collateralAddress) {
        collateralAddress = facet.getAavegotchi(gotchiId).collateral;
    }

    function getCollateralType(uint256 gotchiId) public view returns (uint256 collateralType) {
        collateralType = collateralAddressToType[facet.getAavegotchi(gotchiId).collateral];
    }

    function balanceOf(address input) external view returns (uint256 result) {
        result = facet.balanceOf(input);
    }

    function collaterals(uint256 hauntId) external view returns (address[] memory result) {
        result = collateralFacet.collaterals(hauntId);
    }

    function withdrawLink() external onlyOwner {
       require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function mintFakeTokens() external {
        require(addressToClaimedFakeTokensBool[msg.sender] == false, "Already claimed fake tokens");
        addressToFakeTokens[msg.sender] += 100 ether;
        addressToClaimedFakeTokensBool[msg.sender] = true;
    }

    function mintFakeTokens(address to) external {
        require(addressToClaimedFakeTokensBool[to] == false, "Already claimed fake tokens");
        addressToFakeTokens[to] += 100 ether;
        addressToClaimedFakeTokensBool[to] = true;
    }
}
