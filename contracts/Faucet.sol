/*Once a user joins the platform he/she has to buy specific Tender tokens that are backed by Celo Gold/Celo Dollars in order to transact on the platform. This is what is implemented using smart contracts here */

pragma solidity >=0.8.0;

import "../node_modules/openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Faucet is ReentrancyGuard, Ownable {
    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    address Celo = 0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9;
    address cUSD = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    function withdraw(uint256 withdraw_amount, address token) public {
        require(token == Celo || token == cUSD, "token is not celo or cUSD");

        require(
            address(this).balance >= withdraw_amount,
            "Insufficient balance in faucet for withdrawal request"
        );

        require(
            IERC20(token).transfer(msg.sender, withdraw_amount),
            "Withdrawing cUSD failed."
        );
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    //previously donate
    function deposit_to_bid() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

