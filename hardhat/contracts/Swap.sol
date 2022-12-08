// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/*
*@Authors: Paul Birnbaum, Spoyte.

*@title: Swap Contract. 
*@notice: Creation of the Swap Smart Contract.
*@dev: Allow the user to Bet on a specific Soccer team.
*extra comment
*WARNING I removed the ownable
*/
contract Swap is ERC20, Ownable, ChainlinkClient {
  using Chainlink for Chainlink.Request;

  address public FranceTokenAddress;
  address public BrasilTokenAddress;

  /* chainlink params */
  bytes32 private jobId;
  uint256 private fee;
  /* game status params */
  uint256 public homeScore;
  uint256 public awayScore;

  uint8 public FinalResult = 0;
  /* chainlink event */
  event RequestMultipleFulfilled(
    bytes32 indexed requestId,
    uint256 homeScore,
    uint256 awayScore
  );

  event DepositMade(
    address indexed userAddress,
    uint256 amount,
    uint256 tokenReceived,
    string functionName
  );

  event UserInformation(
    address indexed userAddress,
    uint256 amount_team1_wallet,
    uint256 amount_team2_wallet
  );

  /*
   *@notice: Constructor.
   *@dev: Implement the two tokens contracts address at deployment.
   */
  constructor(
    address _FranceTokenAddress,
    address _BrasilTokenAddress,
    address _LinkToken,
    address _LinkOracle
  ) ERC20("Liquidity Token", "LPT") {
    jobId = "fa38023e44a84b6384c9411401904997";
    setChainlinkToken(_LinkToken);
    setChainlinkOracle(_LinkOracle);
    // 0,1 * 10**18 (Varies by network and job) (here 0.1 link as in testnets)
    fee = (1 * LINK_DIVISIBILITY) / 10;

    FranceTokenAddress = _FranceTokenAddress;
    BrasilTokenAddress = _BrasilTokenAddress;
  }

  /*chainlink functions*/

  /**
   * @notice Request mutiple parameters from the oracle in a single transaction
   */
  function requestMultipleParameters() public {
    Chainlink.Request memory req = buildChainlinkRequest(
      jobId,
      address(this),
      this.fulfillMultipleParameters.selector
    );
    req.add(
      "urlRESULT",
      "https://api.sportsdata.io/v3/soccer/scores/json/GamesByDate/2022-11-15?key=a5acc6cc44dc47fc9918198d29b33e00"
    );
    req.add("pathHOME", "0,HomeTeamScore");

    req.add("pathAWAY", "0,AwayTeamScore");

    sendChainlinkRequest(req, fee); // MWR API.
  }

  /**
   * @notice Fulfillment function for multiple parameters in a single request
   * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
   */
  function fulfillMultipleParameters(
    bytes32 requestId,
    uint256 homeResponse,
    uint256 awayResponse
  ) public recordChainlinkFulfillment(requestId) {
    emit RequestMultipleFulfilled(requestId, homeResponse, awayResponse);
    homeScore = homeResponse;
    awayScore = awayResponse;
    if (homeScore > awayScore) FinalResult = 1;
    else if (homeScore == awayScore) FinalResult = 2;
    else FinalResult = 3;
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  function withdrawMatic() public payable onlyOwner {
    require(walletBalance() != 0, "There is no Matic in the Contract");
    (bool sent, ) = payable(msg.sender).call{ value: walletBalance() }("");
    require(sent, "Failure Coudn't send Matic");
  }

  /*
   *@notice: Public function that shows the balance of France Tokens in the contract
   *@return: Balance of the France Token in this contract.
   */
  function getReserveFrance() public view returns (uint256) {
    uint256 FranceReserve = ERC20(FranceTokenAddress).balanceOf(address(this));
    return (FranceReserve);
  }

  /*
   *@notice: Public function that shows the balance of Brasil Tokens in the contract
   *@return: Balance of the Brasil Token in this contract.
   */
  function getReserveBrasil() public view returns (uint256) {
    uint256 BrasilReserve = ERC20(BrasilTokenAddress).balanceOf(address(this));
    return (BrasilReserve);
  }

  function contractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /*
   *@notice: Public function that show the balance of Tokens in the User's Wallet
   *@return: Balance of the France and Brasil Token in the User's Wallet.
   */
  function getBalanceWalletFrance() public view returns (uint256) {
    uint256 balanceFranceToken = ERC20(FranceTokenAddress).balanceOf(
      msg.sender
    );
    return (balanceFranceToken);
  }

  function getBalanceWalletBrasil() public view returns (uint256) {
    uint256 balanceBrasilToken = ERC20(BrasilTokenAddress).balanceOf(
      msg.sender
    );
    return (balanceBrasilToken);
  }

  function walletBalance() public view returns (uint256) {
    return (msg.sender.balance);
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

  function addLiquidity(uint128 _amountTeamA, uint128 _amountTeamB)
    public
    onlyOwner
  {
    ERC20(FranceTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _amountTeamA
    );

    ERC20(BrasilTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _amountTeamB
    );
  }

  /*
   *@notice: Allow the Owner to remove Liquidity in the Pool when the Bet is Over.
   *@dev: This function is restricted to the Owner of the Contract.
   */
  function removeLiquidity() public onlyOwner {
    ERC20(BrasilTokenAddress).transfer(msg.sender, getReserveBrasil());
    ERC20(FranceTokenAddress).transfer(msg.sender, getReserveFrance());
  }

  function deposit_swapBRAtoFR() public payable {
    require(msg.value > 0, "You didn't provide any funds");

    France(FranceTokenAddress).mint(msg.sender, msg.value);
    Brasil(BrasilTokenAddress).mint(msg.sender, msg.value);

    uint256 franceTokenReserve = getReserveFrance();
    uint256 brasilTokenReserve = getReserveBrasil() - msg.value;

    ERC20(BrasilTokenAddress).transferFrom(
      msg.sender,
      address(this),
      msg.value
    );

    uint256 frReturn = (msg.value * franceTokenReserve) /
      (brasilTokenReserve + msg.value);

    ERC20(FranceTokenAddress).transfer(msg.sender, frReturn);
    emit DepositMade(msg.sender, msg.value, frReturn, "deposit_swapBRAtoFR");
  }

  function deposit_swapFRtoBRA() public payable {
    require(msg.value > 0, "You didn't provide any funds");

    uint256 franceTokenReserve = getReserveFrance() - msg.value;
    uint256 brasilTokenReserve = getReserveBrasil();

    France(FranceTokenAddress).mint(msg.sender, msg.value);
    Brasil(BrasilTokenAddress).mint(msg.sender, msg.value);

    ERC20(FranceTokenAddress).transferFrom(
      msg.sender,
      address(this),
      msg.value
    );

    uint256 braReturn = (msg.value * brasilTokenReserve) /
      (franceTokenReserve + msg.value);

    ERC20(BrasilTokenAddress).transfer(msg.sender, braReturn);

    emit DepositMade(msg.sender, msg.value, braReturn, "deposit_swapFRtoBRA");
  }

  /*
   *@notice: User send back the Token and Swap it for some ETH/MATIC If the User wins his bet.
   *@notice: User send back the token but don't swap it If he losses.
   *@dev: Function to be call when the game is over.
   */

  function gameOver() public {
    require(FinalResult > 0, "The match is not finish yet");

    uint256 balanceFranceToken = getBalanceWalletFrance();
    uint256 balanceBrasilToken = getBalanceWalletBrasil();

    if (FinalResult == 1) {
      ERC20(FranceTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceFranceToken
      );
      ERC20(BrasilTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceBrasilToken
      );
      (bool sent, ) = payable(msg.sender).call{ value: balanceFranceToken }("");
      require(sent, "Failed to send Ether");
    } else if (FinalResult == 3) {
      ERC20(BrasilTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceBrasilToken
      );
      ERC20(FranceTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceFranceToken
      );
      (bool sent, ) = payable(msg.sender).call{ value: balanceBrasilToken }("");
      require(sent, "Failed to send Ether");
    }
    // In case of a draw, EXPERIMENTAL
    else if (FinalResult == 2) {
      uint256 total = balanceBrasilToken + balanceFranceToken;
      ERC20(FranceTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceFranceToken
      );
      ERC20(BrasilTokenAddress).transferFrom(
        msg.sender,
        address(this),
        balanceBrasilToken
      );

      (bool sent, ) = payable(msg.sender).call{ value: (total / 2) }("");
      require(sent, "Failed to send Ether");
    }
  }

  receive() external payable {}

  fallback() external payable {}
}
