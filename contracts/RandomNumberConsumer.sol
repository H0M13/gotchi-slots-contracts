pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNumberConsumer is VRFConsumerBase, Ownable {

    bytes32 public keyHash;
    uint256 public fee;
    address public vrfCoordinator;
    address public link;
    uint256 public randomResult;

    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => uint256) public requestIdToRandomNumber;

    mapping(address => uint256) public addressToFakeChips;

    event RequestedRandomness(bytes32 requestId);
    event SpinsOutcome(bytes32 requestId, address player, uint256 randomResult, uint256 payout1, uint256 payout2, uint256 payout3, uint256 payout4, uint256 payout5, uint256 payout6, uint256 payout7, uint256 payout8, uint256 payout9, uint256 payout10);

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
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() public payable returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToAddress[requestId] = msg.sender;
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
        randomResult = randomness;
        address requestAddress = requestIdToAddress[requestId];
        requestIdToRandomNumber[requestId] = randomness;
        uint256[] memory expandedValues = expand(randomness, 10);
        uint[] memory payouts = new uint[](10);
        for (uint i=0; i<10; i++) {
            uint256 spinValue = (expandedValues[i] % 1000) + 1;
            if (spinValue <= 700) {
                payouts[i] = 0;
            } 
            else if (spinValue > 700 && spinValue <= 850) {
                payouts[i] = 10;
            }
            else if (spinValue > 850 && spinValue <= 950) {
                payouts[i] = 20;
            }
            else if (spinValue > 950 && spinValue <= 1000) {
                payouts[i] = 50;
            }
        }

        uint totalPayout;
         for (uint i=0; i<10; i++) {
             totalPayout += payouts[i];
        }

        addressToFakeChips[requestAddress] += totalPayout;
        emit SpinsOutcome(requestId, requestAddress, payouts[0], payouts[1], payouts[2], payouts[3], payouts[4], payouts[5], payouts[6], payouts[7], payouts[8], payouts[9], payouts[10]);
    }

    function withdrawLink() external onlyOwner {
       require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function mintFakeChips() external {
        addressToFakeChips[msg.sender] += 100;
    }

    function mintFakeChips(address to) external {
        addressToFakeChips[to] += 100;
    }
}
