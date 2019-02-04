pragma solidity ^0.5.2;

import "./EIP20Factory.sol";
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function create(address recipient,uint _value) public returns (bool);
  function destroy(address recipient,uint _value) public returns (bool);
}

contract UCURRENCIES is EIP20Factory{

    address UCASHAddress = 0xbD52C5265B94f727f0616f831b011c17e1f235A2;
    uint public ratioD = 10**8; //ratio denominator

    constructor() public {
        tokenRatios[UCASHAddress] = ratioD;
        tokenList.push(UCASHAddress);

    }
    mapping(address=>uint) public tokenRatios;
    address[] public tokenList;

    //allow users to create tokens
    //peg them to UCASH up to a certain limit (allow trades)
    //UCASHRatio is out of 10**8. 10**8 means one UCASH to one token.
    function createToken(uint _limit, uint8 decimals,string memory _name, string memory _symbol,uint UCASHRatio) public{
        require(decimals<=18);
        address token = createEIP20(0, _name, decimals, _symbol,_limit);

        uint realTokenRatio = getRealTokenRatio(UCASHRatio, decimals);
        tokenRatios[token] = realTokenRatio;
        tokenList.push(token);
    }



     function getRealTokenRatio(uint UCASHRatio,uint decimals) public pure returns (uint){
        return ((UCASHRatio*10**decimals)/10**8);
    }

    function buyTokens(address token, uint amount) public{
        require(tokenRatios[token]!=0);

        ERC20(UCASHAddress).transferFrom(msg.sender,address(this),amount);
        uint tokensToCredit = tokenRatios[token]*amount/ratioD;
        ERC20(token).create(msg.sender,tokensToCredit);
    }

    function redeemTokens(address token, uint amount) public{
        require(tokenRatios[token]!=0);

        ERC20(token).destroy(msg.sender,amount);

        uint UCASHtoSend = ratioD*amount/tokenRatios[token];
        ERC20(UCASHAddress).transfer(msg.sender,UCASHtoSend);
    }

    function convertTokens(address _from, address _to, uint amount) public {
        require(tokenRatios[_from]!=0);

        if(_from == UCASHAddress){
            buyTokens(_to,amount);
        }else {
            uint tokensToDebit = amount;
            uint tokensToCredit = tokenRatios[_to]*amount/tokenRatios[_from];

            ERC20(_from).destroy(msg.sender,tokensToDebit);
            ERC20(_to).create(msg.sender,tokensToCredit);
        }

    }

    function getTokenListLength() public view returns (uint) {
        return tokenList.length;
    }
}
