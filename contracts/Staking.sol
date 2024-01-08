// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@zetachain/protocol-contracts/contracts/zevm/SystemContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/zContract.sol";

contract Staking is zContract {
    SystemContract public immutable systemContract;

    constructor(address systemContractAddress) {
        systemContract = SystemContract(systemContractAddress);
    }

    modifier onlySystem() {
        require(
            msg.sender == address(systemContract),
            "Only system contract can call this function"
        );
        _;
    }

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {
        // TODO: implement the logic
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@zetachain/protocol-contracts/contracts/zevm/SystemContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/zContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@zetachain/toolkit/contracts/BytesHelperLib.sol";

contract Staking is ERC20, zContract {
    SystemContract public immutable systemContract;
    uint256 public immutable chainID;
    uint256 constant BITCOIN = 18332;

    uint256 public rewardRate = 1;

    error SenderNotSystemContract();
    error WrongChain(uint256 chainID);
    error UnknownAction(uint8 action);
    error Overflow();
    error Underflow();
    error WrongAmount();
    error NotAuthorized();
    error NoRewardsToClaim();

    mapping(address => uint256) public stake;
    mapping(address => bytes) public withdraw;
    mapping(address => address) public beneficiary;
    mapping(address => uint256) public lastStakeTime;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainID_,
        address systemContractAddress
    ) ERC20(name_, symbol_) {
        systemContract = SystemContract(systemContractAddress);
        chainID = chainID_;
    }

    modifier onlySystem() {
        require(
            msg.sender == address(systemContract),
            "Only system contract can call this function"
        );
        _;
    }

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {
        if (chainID != context.chainID) {
            revert WrongChain(context.chainID);
        }

        address staker = BytesHelperLib.bytesToAddress(context.origin, 0);

        uint8 action = chainID == BITCOIN
            ? uint8(message[0])
            : abi.decode(message, (uint8));

        if (action == 1) {
            stakeZRC(staker, amount);
        } else if (action == 2) {
            unstakeZRC(staker);
        } else if (action == 3) {
            setBeneficiary(staker, message);
        } else if (action == 4) {
            setWithdraw(staker, message, context.origin);
        } else {
            revert UnknownAction(action);
        }
    }
}
function stakeZRC(address staker, uint256 amount) internal {
    stake[staker] += amount;
    if (stake[staker] < amount) revert Overflow();

    lastStakeTime[staker] = block.timestamp;
    updateRewards(staker);
}

function updateRewards(address staker) internal {
    uint256 rewardAmount = queryRewards(staker);

    _mint(beneficiary[staker], rewardAmount);
    lastStakeTime[staker] = block.timestamp;
}

function queryRewards(address staker) public view returns (uint256) {
    uint256 timeDifference = block.timestamp - lastStakeTime[staker];
    uint256 rewardAmount = timeDifference * stake[staker] * rewardRate;
    return rewardAmount;
}
mpus
Home
Earn
Learn
Balance Amount Hidden


hestaine
Campaigns
Omnichain Staking Unleashed with ZetaChain
Quest 2: Creating an Omnichain Staking Contract
Quest
Quest 2: Creating an Omnichain Staking Contract
Ongoing
Start: January 8, 2024, 05:00
End: January 19, 2024, 05:00

All times are shown in Africa/Lagos (GMT +01:00)

Ends in
10

Days

22

Hrs

4

Min


$1,000 Total Rewards
$2 per reward

406 Players Joined
Submit Quest
A screenshot of your completed Staking.sol smart contract
A screenshot of your completed Staking.sol smart contract


Upload File
No file chosen
Format: PDF, PNG, JPG up to 8 MB

Your submission will be final and cannot be modified or withdrawn later. Please review your inputs carefully.

I acknowledge that I cannot amend or retract my submission once it has been submitted.
Learning Outcomes
By the end of this quest, you will be able to:

Clone a boilerplate Hardhat project from ZetaChain
Describe how an omnichain staking contract works
Build an omnichain staking contract
Quest Details
Introduction
In this quest, we'll be creating our first omnichain staking contract, designed to accept tokens from various connected chains (including Bitcoin) and stake them on ZetaChain. Native tokens sent to ZetaChain and converted into ZRC-20s will remain secured in the contract until the staker decides to withdraw them. The staking rewards will accumulate at a predetermined rate, directly proportional to the quantity of tokens staked.

Through this quest, we’ll also be learning how to use the onCrossChainCall function properly to dispatch different code logics, as well as how to withdraw tokens correctly both to EVM-based chains as well as to Bitcoin.

Hope you’re pumped, let’s go! 🔥

For technical help on the StackUp platform & quest-related questions, join our Discord, head to the zetachain-helpdesk channel and look for the correct thread to ask your question.

If you have any questions or feedback with regards to the platform, do head over to the 🆘 | v20-feedback-and-discussion channel!

Deliverables
This quest has 1 deliverable.

A screenshot of your completed Staking.sol smart contract
It's better with others!
Join a community of learners and questers through pathways and campaigns. Share your progress, get help, interact and ask questions!

Go to Discord
Not on Discord?
Quest Steps
Total Steps: 8

Step 1:
Overview of Omnichain Staking Contract
In the previous quest, we touched on omnichain smart contracts and how they can be used to facilitate cross-chain interactions. Now, let’s put that to practice in this quest by creating an omnichain staking contract!

The omnichain contract we’ll be creating will be capable of receiving tokens from connected chains and staking them on ZetaChain.
 Native tokens deposited to ZetaChain as ZRC-20s will be locked in the contract until withdrawn by the staker. 
Rewards will be accrued at a fixed rate proportionally to the amount of tokens staked.
In this setup, the staker deposits tokens into the contract and must specify a beneficiary address for receiving rewards, which can be the staker's own address. Only the staker has the authority to withdraw the staked tokens, and these must be withdrawn back to their chain of origin.

The rewards accrued in the contract can only be withdrawn by the designated beneficiary.

To maintain simplicity, this contract will be compatible with only one connected chain at a time. The chain ID for the connected chain is provided to the contract's constructor, ensuring that the contract interacts only with compatible chains.

Step 2:
Setting Up Your Environment
Environment Configuration

Let’s start by configuring our environment. There are 3 prerequisites required - Node.js, Git and Yarn. We’ll start by checking Node.js; open up your terminal on your device.

To check if you have already installed Node.js, you can run the following command which will return you the Node.js version number if you have it installed:

node --version
If a version number is not returned then you will need to install Node.js, which you can do so here. You’ll also need to make sure that your Node.js version is 18 or above; if it's not, then you can refer to this guide for a reference on how to update the version you’re using.

Next, to check if you have installed Git, you run the following command in your terminal:

git --version
Similarly, if a version number is returned, then Git is installed. If Git is not installed, then you can refer to this guide to install and configure Git on your device.

Lastly, we’ll be checking if Yarn is installed. Similarly, you can run the following command to check if you have already have it installed on your device:

yarn --version
If a version number is not returned, then you can checkout the installation guide here.

Create Project

Now that we have all the prerequisites required, let’s go ahead and initialize a new project! First, in your terminal, navigate to the directory where you plan to store your project. Then, run the command below to clone the Hardhat contract template provided by ZetaChain:

git clone https://github.com/zeta-chain/template
⚠️ Note that if you’re using the same ZetaChain template repository as you did in the previous campaign, you’ll need to run the command yarn add @zetachain/toolkit to update your dependencies.

Next, proceed to install the necessary libraries and dependencies by running the following command:

cd template && yarn
Now, we can run a Hardhat task created by the ZetaChain team to jumpstart the creation of our omnichain contract:

npx hardhat omnichain Staking
If you look in the contracts folder, you should see a new smart contract Staking.sol in it. And we’re ready to start building!

Step 3:
Omnichain Contract Design
Before we proceed further, let’s do a quick recap of what we aim to achieve with our Staking omnichain contract. The contract needs to be able to handle the following actions.


Omnichain Contract Design
Called from a connected chain by the staker:

Staking tokens by depositing them into the staking omnichain contract on ZetaChain
Unstaking tokens by withdrawing them to the chain from which they originate
Setting the beneficiary address
Setting the withdraw address
Called on ZetaChain:

Claiming rewards by the beneficiary
Querying the pending rewards
Since omnichain contracts only have 1 function onCrossChainCall that gets activated when the contract is triggered from a connected chain, and since we need to execute different logic based different situations (e.g. stake, unstake, set beneficiary, etc), it's essential to embed the action code within the message parameter of onCrossChainCall (we'll see this later on, its basically just an if-else statement).

Note that even though the message value is encoded differently in EVM-based chains as compared to Bitcoin, the first bytes of the message will always be the action code encoded as uint8.

Step 4:
Handling the Omnichain Contract Call
Alright, now let’s start building our omnichain staking contract! First, using an IDE of your choice, open up the Staking.sol smart contract. Then, edit your smart contract such that it looks like the following:

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@zetachain/protocol-contracts/contracts/zevm/SystemContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/zContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@zetachain/toolkit/contracts/BytesHelperLib.sol";

contract Staking is ERC20, zContract {
    SystemContract public immutable systemContract;
    uint256 public immutable chainID;
    uint256 constant BITCOIN = 18332;

    uint256 public rewardRate = 1;

    error SenderNotSystemContract();
    error WrongChain(uint256 chainID);
    error UnknownAction(uint8 action);
    error Overflow();
    error Underflow();
    error WrongAmount();
    error NotAuthorized();
    error NoRewardsToClaim();

    mapping(address => uint256) public stake;
    mapping(address => bytes) public withdraw;
    mapping(address => address) public beneficiary;
    mapping(address => uint256) public lastStakeTime;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainID_,
        address systemContractAddress
    ) ERC20(name_, symbol_) {
        systemContract = SystemContract(systemContractAddress);
        chainID = chainID_;
    }

    modifier onlySystem() {
        require(
            msg.sender == address(systemContract),
            "Only system contract can call this function"
        );
        _;
    }

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {
        if (chainID != context.chainID) {
            revert WrongChain(context.chainID);
        }

        address staker = BytesHelperLib.bytesToAddress(context.origin, 0);

        uint8 action = chainID == BITCOIN
            ? uint8(message[0])
            : abi.decode(message, (uint8));

        if (action == 1) {
            stakeZRC(staker, amount);
        } else if (action == 2) {
            unstakeZRC(staker);
        } else if (action == 3) {
            setBeneficiary(staker, message);
        } else if (action == 4) {
            setWithdraw(staker, message, context.origin);
        } else {
            revert UnknownAction(action);
        }
    }
}
Solidity (Ethereum)
Now let’s break down what we just added in!

Imports & Variables Instantiation

First, we imported the ERC20 contract from OpenZeppelin to manage our ERC20 staking reward token. We also imported BytesHelperLib from ZetaChain's toolkit for utility functions to convert bytes into addresses and vice versa.

We also instantiate two uint256 variables chainID and BITCOIN that are used to store the chainIDs of the connected chain and Bitcoin respectively. chainID is set in the constructor and BITCOIN is a constant value of 18332 (ZetaChain uses this fixed value to represent Bitcoin).

Our contract needs to be able to store the staker's staked balance, withdraw address and beneficiary address; we use the mappings we’ve defined for this.

Next, we modify the constructor to accept three additional arguments: name_, symbol_, and chainID_. The name_ and symbol_ arguments will be used to initialize the ERC20 token (staking rewards). Note that this means that our omnichain contract is also doubling up as our ERC20 staking rewards token. The chainID_ argument is used to set the chainID variable.

OnCrossChainCall

Recall that onCrossChainCall is the function that will be called by the system contract when a user triggers the omnichain contract from a connected chain.

First, we check that the omnichain contract is called from the same connected chain as the one specified in the constructor. context.chainID can be used to get the chain ID of the connected chain from which the omnichain contract was called.

context.origin contains information about the address from which the transaction that triggered the omnichain contract was broadcasted.

For EVM-based chains, context.origin is the actual address of the account which broadcasted the transaction. For example - 0x2cD3D070aE1BD365909dD859d29F387AA96911e1
For Bitcoin, context.origin is the first 20 bytes of the hexidecimal representation of the Bitcoin address. For example, if the Bitcoin address is tb1q2dr85d57450xwde6560qyhj7zvzw9895hq25tx, the hexadecimal representation of the address is 0x7462317132647238356435373435...7132357478. We’ll take the first 20 bytes (or 40 characters, excluding the 0x prefix), so context.origin is 0x7462317132647238356435373435307877646536.
💡 Note that for Bitcoin, context.origin does not contain all the information about the address from which the transaction was broadcasted, but it can be used to identify the account that broadcasted the transaction.

BytesHelperLib.bytesToAddress is used to decode the staker's identifier from the context.origin bytes. We will be using staker as a key in the stakes, withdraw and beneficiary mappings.

The message parameter contains the data that was passed to the omnichain contract when it was called from the connected chain. In our design the first value in the message is the action code.

For EVM-based chains, use abi.decode to decode the first value of the message as a uint8
For Bitcoin take the first byte of the message and convert it to uint8
Finally, based on the action code derived, we’ll call the corresponding functions, which we’ll define in the subsequent steps. Here’s what each action code represents:

1 - Stake ZRC-20 tokens
2 - Unstake ZRC-20 tokens
3 - Set beneficiary address
4 - Set withdraw address
Let’s proceed to build the functions needed, starting with the functions pertaining to staking and unstaking.

Step 5:
Staking & Unstaking ZRC-20 Tokens
Staking ZRC-20 Tokens

stakeZRC is a function that will be called by onCrossChainCall to stake the deposited tokens. Copy the code below and paste it in your smart contract; these are the functions that’ll be handling the staking functionality.

function stakeZRC(address staker, uint256 amount) internal {
    stake[staker] += amount;
    if (stake[staker] < amount) revert Overflow();

    lastStakeTime[staker] = block.timestamp;
    updateRewards(staker);
}

function updateRewards(address staker) internal {
    uint256 rewardAmount = queryRewards(staker);

    _mint(beneficiary[staker], rewardAmount);
    lastStakeTime[staker] = block.timestamp;
}

function queryRewards(address staker) public view returns (uint256) {
    uint256 timeDifference = block.timestamp - lastStakeTime[staker];
    uint256 rewardAmount = timeDifference * stake[staker] * rewardRate;
    return rewardAmount;
}
Solidity (Ethereum)
stakeZRC increases the staker's balance in the contract. The function also updates the timestamp of when the staking happened last, and calls the updateRewards function to update the rewards for the staker.

updateRewards calculates the rewards for the staker and mints them to the beneficiary address (recall that our smart contract is an ERC20 token too). The function also updates the timestamp of when the staking happened last.

queryRewards is simply a view-only function that can be used to get the reward amount the staker can expect to get at this current moment.

Unstaking ZRC-20 Tokens

Conversely, unstakeZRC is a function that will be called by onCrossChainCall to unstake the deposited tokens. Copy the code below and paste it in your smart contract; this function handles the logic required for unstaking deposited tokens:

function unstakeZRC(address staker) internal {
    uint256 amount = stake[staker];

    updateRewards(staker);

    address zrc20 = systemContract.gasCoinZRC20ByChainId(chainID);
    (, uint256 gasFee) = IZRC20(zrc20).withdrawGasFee();

    if (amount < gasFee) revert WrongAmount();

    bytes memory recipient = withdraw[staker];

    stake[staker] = 0;

    IZRC20(zrc20).approve(zrc20, gasFee);
    IZRC20(zrc20).withdraw(recipient, amount - gasFee);

    if (stake[staker] > amount) revert Underflow();

    lastStakeTime[staker] = block.timestamp;
}
function setBeneficiary(address staker, bytes calldata message) internal {
    address beneficiaryAddress;
    if (chainID == BITCOIN) {
        beneficiaryAddress = BytesHelperLib.bytesToAddress(message, 1);
    } else {
        (, beneficiaryAddress) = abi.decode(message, (uint8, address));
    }
    beneficiary[staker] = beneficiaryAddress;
}
function setWithdraw(
    address staker,
    bytes calldata message,
    bytes memory origin
) internal {
    bytes memory withdrawAddress;
    if (chainID == BITCOIN) {
        withdrawAddress = bytesToBech32Bytes(message, 1);
    } else {
        withdrawAddress = origin;
    }
    withdraw[staker] = withdrawAddress;
}

function bytesToBech32Bytes(
    bytes calldata data,
    uint256 offset
) internal pure returns (bytes memory) {
    bytes memory bech32Bytes = new bytes(42);
    for (uint i = 0; i < 42; i++) {
        bech32Bytes[i] = data[i + offset];
    }

    return bech32Bytes;
}
function claimRewards(address staker) external {
    if (beneficiary[staker] != msg.sender) revert NotAuthorized();
    uint256 rewardAmount = queryRewards(staker);
    if (rewardAmount <= 0) revert NoRewardsToClaim();
    updateRewards(staker);
}