// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
*@Author: Paul Birnbaum.

*@title: France Token . 
*@notice: Creation of the France Token.
*@dev: Will create 10000 tokens and can mint more later.
extra comment
*/
contract France is ERC20 {
  constructor(uint16 oddTeam) ERC20("France", "FR") {
    _mint(msg.sender, oddTeam * 10**decimals());
  }

  bool isSmartContractOwnerSet = false;
  address public smartContractOwner;

  function setSmartContractOwner() external {
    require(
      isSmartContractOwnerSet == false,
      "This Conctract is not the Contract's Owner"
    );
    smartContractOwner = msg.sender;
    isSmartContractOwnerSet = true;
  }

  modifier onlySmartContractOwner() {
    require(
      isSmartContractOwnerSet && msg.sender == smartContractOwner,
      "You are not the Smart Contract Owner"
    );
    _;
  }

  //@notice: Allow to mint more token when the user want to make a bet
  function mint(address _address, uint256 _amount)
    external
    onlySmartContractOwner
  {
    _mint(_address, _amount);
  }

  // 0xde12A52cd5AB09b995404f7145A77b621eB5946cd
}

/*
 *@title: Brasil Token .
 *@notice: Creation of the Brasil Token.
 *@dev: Will create 10000 tokens and can mint more later.
 */
contract Brasil is ERC20 {
  constructor(uint16 oddTeam) ERC20("Brasil", "BRA") {
    _mint(msg.sender, oddTeam * 10**decimals());
  }

  bool isSmartContractOwnerSet = false;
  address public smartContractOwner;

  function setSmartContractOwner() external {
    require(
      isSmartContractOwnerSet == false,
      "This Conctract is not the Contract's Owner"
    );
    smartContractOwner = msg.sender;
    isSmartContractOwnerSet = true;
  }

  modifier onlySmartContractOwner() {
    require(
      isSmartContractOwnerSet && msg.sender == smartContractOwner,
      "You are not the Smart Contract Owner"
    );
    _;
  }

  //@notice: Allow to mint more token when the user want to make a bet
  function mint(address _address, uint256 _amount)
    external
    onlySmartContractOwner
  {
    _mint(_address, _amount);
  }

  // 0xde12A52cd5AB09b995404f7145A77b621eB5946cd
}
