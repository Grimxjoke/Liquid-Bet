// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens.sol";
import "hardhat/console.sol";

/*
*@Author: Paul Birnbaum.

*@title: Swap Contract. 
*@notice: Creation of the Swap Smart Contract.
*@dev: Allow the user to Bet on a specific Soccer team.
*/
contract Swap is ERC20, Ownable {
  address public FranceTokenAddress;
  address public BrasilTokenAddress;

  // mapping (address => uint) balance;

  event FranceBalanceWallet(uint256);
  event BrasilBalanceWallet(uint256);
  event thoughtThis(string);
  event Initialization(address sender, uint256 time);

  /*
   *@notice: Constructor.
   *@dev: Implement the two tokens contracts address at deployment.
   */
  constructor(address _FranceTokenAddress, address _BrasilTokenAddress)
    ERC20("Liquidity Token", "LPT")
  {
    FranceTokenAddress = _FranceTokenAddress;
    BrasilTokenAddress = _BrasilTokenAddress;
    console.log("Contract Deployed");
  }

  /*
   *@notice: Public function that shows the balance of France Tokens in the contract
   *@return: Balance of the France Token in this contract.
   */
  function getReserveFrance() public view returns (uint256) {
    uint256 FranceReserve = ERC20(FranceTokenAddress).balanceOf(address(this));
    //Result in Eth
    return (FranceReserve / 1e18);
  }

  /*
   *@notice: Public function that shows the balance of Brasil Tokens in the contract
   *@return: Balance of the Brasil Token in this contract.
   */
  function getReserveBrasil() public view returns (uint256) {
    uint256 BrasilReserve = ERC20(BrasilTokenAddress).balanceOf(address(this));
    //Result in Eth
    return (BrasilReserve / 1e18);
  }

  /*
   *@notice: Public function that show the balance of Tokens in the User's Wallet
   *@return: Balance of the France and Brasil Token in the User's Wallet.
   */
  function getBalanceWalletFrance() public view returns (uint256) {
    uint256 balanceFranceToken = ERC20(FranceTokenAddress).balanceOf(
      msg.sender
    );
    //Result in Eth
    return (balanceFranceToken / 1e15);
  }

  function getBalanceWalletBrasil() public view returns (uint256) {
    uint256 balanceBrasilToken = ERC20(BrasilTokenAddress).balanceOf(
      msg.sender
    );
    //Result in Eth
    return (balanceBrasilToken / 1e15);
  }

  function ownTokenContracts() public onlyOwner {
    France(FranceTokenAddress).setSmartContractOwner();
    Brasil(BrasilTokenAddress).setSmartContractOwner();
  }

  /*
   *@notice: Allow the Owner to add Liquidity in the Pool for the upcomming Users.
   *@dev: This function is restricted to the Owner of the Contract.
   *@dev: Need to approve the Contract address from each Tokens Contract before calling the function.
   */

  //Eth
  function addLiquidity(uint256 _amount) public onlyOwner {
    _amount *= 1e18;
    ERC20(FranceTokenAddress).transferFrom(msg.sender, address(this), _amount);
    ERC20(BrasilTokenAddress).transferFrom(msg.sender, address(this), _amount);
  }

  /*
   *@notice: Allow the Owner to remove Liquidity in the Pool when the Bet is Over.
   *@dev: This function is restricted to the Owner of the Contract.
   */
  function removeLiquidity() public onlyOwner {
    ERC20(BrasilTokenAddress).transfer(msg.sender, getReserveBrasil());
    ERC20(FranceTokenAddress).transfer(msg.sender, getReserveFrance());
  }

  /*
   *@notice: Allow the User to bet on one team (1/3).
   *@dev: Allow the user to deposit some ETH/Matic
   *@dev: Mint some tokens in the User's wallet.
   */

  //eth
  function deposit() public payable {
    require(msg.value > 0, "You didn't provide any funds");
    France(FranceTokenAddress).mint(msg.sender, msg.value);
    Brasil(BrasilTokenAddress).mint(msg.sender, msg.value);
  }

  /*
   *@notice: Allow the User to bet on one team (2/3).
   *@dev: Allow the User to deposit some of the unwanted token for a swap.
   *@dev: Need to approve the Contract address from each Tokens Contract before calling the function.
   */
  //Wei
  function sendBRAToken(uint256 _braAmount) public {
    // _braAmount *= 1e18;
    ERC20(BrasilTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _braAmount
    );
  }

  //Wei
  function sendFRToken(uint256 _frAmount) public {
    _frAmount *= 1e18;
    ERC20(FranceTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _frAmount
    );
  }

  /*
   *@notice: Allow the User to bet on one team (3/3)
   *@dev: Send wanted token from the liquidity pool back to the user.
   */

  function receivedFrToken(uint256 _braAmount) public {
    // _braAmount *= 1e18;
    uint256 franceTokenReserve = getReserveFrance();
    uint256 brasilTokenReserve = getReserveBrasil();
    uint256 frReturn = (_braAmount * franceTokenReserve) /
      (brasilTokenReserve + _braAmount);

    ERC20(FranceTokenAddress).transfer(msg.sender, frReturn);
  }

  function receivedBraToken(uint256 _frAmount) public {
    _frAmount *= 1e18;

    uint256 franceTokenReserve = getReserveFrance();
    uint256 brasilTokenReserve = getReserveBrasil();
    uint256 braReturn = (_frAmount * brasilTokenReserve) /
      (franceTokenReserve + _frAmount);

    ERC20(BrasilTokenAddress).transfer(msg.sender, braReturn);
  }


  function balance() public view returns(uint) {
  return ((msg.sender.balance) / 1e14) ;
  }

  function contractBalance() public view returns(uint) {
    return address(this).balance / 1e14;
  }

  //Will be 1 for France win, 2 for Draw and 3 for Brasil's win.
  //Will be send a value at the end of the match.
  uint256 public FinalResult = 1;

  // Allow us to test the final result before connecting to the Chainlink Node
  function setFinalResult(uint256 _winner) public {
    FinalResult = _winner;
  }
  

  /*
   *@notice: Send back the Token and Swap it for some ETH/MATIC If the User wins his bet.
   *@notice: Send back the token but don't swap it If he losses.
   *@dev: Function to be call when the game is over.
   */
  
  

  function gameOver() public {
    require(FinalResult > 0, "The match is not finish yet");


    uint256 balanceFranceToken = getBalanceWalletFrance();
    // uint256 balanceBrasilToken = getBalanceWalletBrasil();

    if (FinalResult == 1) {
      ERC20(FranceTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceFranceToken
      );
    }
  }

  function backMoney() public  {
    uint256 balanceFranceToken = getBalanceWalletFrance();
    if(FinalResult == 1){
      payable(msg.sender).transfer(balanceFranceToken);
      
    }
  }

    
    // else if (FinalResult == 3) {
    //   ERC20(BrasilTokenAddress).transferFrom(
    //     msg.sender,
    //     address(this),
    //     balanceBrasilToken
    //   );
    //   payable(msg.sender).transfer(balanceBrasilToken);
    // } else if (FinalResult == 2) {
    //   ERC20(FranceTokenAddress).transferFrom(
    //     msg.sender,
    //     address(this),
    //     balanceFranceToken
    //   );
    //   ERC20(BrasilTokenAddress).transferFrom(
    //     msg.sender,
    //     address(this),
    //     balanceBrasilToken
    //   );
    //   payable(msg.sender).transfer(
    //     (balanceFranceToken + balanceBrasilToken) / 2
    //   ); //Experimental...
    // }

    // return (balanceFranceToken, balanceBrasilToken);
  

  // 0xde12A52cd5AB09b995404f7145A77b621eB5946cd8et
}
