pragma solidity ^0.8.9;
pragma abicoder v2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

using SafeMath for uint256;

contract NFT is ERC721URIStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    ISwapRouter public immutable swapRouter;

    address public owner;
    uint256 private feePercent;
    mapping(address => uint256) private feeAmount;
    mapping(address => uint256) private balances;
    mapping(uint256 => Holder) public holders;
    EnumerableSet.AddressSet private allowedTokens;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    struct Holder {
        address holderAddress;
        address[] tokensAddresses;
        uint256[] tokensAmounts;
        bool flag;
    }

    constructor(ISwapRouter _swapRouter, address[] memory _allowedTokensAddresses) ERC721("NFT", "NFT") {
        owner = msg.sender;
        swapRouter = _swapRouter;
        changeAllowedTokens(_allowedTokensAddresses, true);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }

    function changeAllowedTokens (address[] memory _tokenAddresses, bool _isAllowed) internal onlyOwner {
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            if (!_isAllowed && feeAmount[_tokenAddresses[i]] != 0) {
                continue;
            }
            if (_isAllowed) {
                allowedTokens.add(_tokenAddresses[i]);
            } else {
                allowedTokens.remove(_tokenAddresses[i]);
            }
        }
    }

    function addAllowedTokens(address[] memory _tokenAddresses) onlyOwner public  {
        changeAllowedTokens(_tokenAddresses, true);
    }

    function removeAllowedTokens(address[] memory _tokenAddresses) onlyOwner public  {
        changeAllowedTokens(_tokenAddresses, false);
    }

    function withdrawFee() onlyOwner public {
        for (uint i = 0; i < allowedTokens.length(); i++) {
            address tokenAddress = allowedTokens.at(i);

            if (feeAmount[tokenAddress] != 0) {
                ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenAddress,
                    tokenOut: USDC,
                    fee: 3000,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountIn: feeAmount[tokenAddress],
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                uint256 amount = swapRouter.exactInputSingle(params);

                delete feeAmount[tokenAddress];
            }
        }
    }

    function checkAllowedTokens(address[] calldata _tokensAddresses) internal returns (bool) {
        for (uint i = 0; i < _tokensAddresses.length; i++) {
            if (!allowedTokens.contains(_tokensAddresses[i])) {
                return false;
            }
        }
        return true;
    }

    function collectFeeAndAmount(address[] calldata _tokensAddresses, uint256[] calldata _tokensAmounts) internal returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokensAmounts.length);

        require(checkAllowedTokens(_tokensAddresses));

        for (uint i = 0; i < _tokensAddresses.length; i++) {
            IERC20Metadata tokenAddress = IERC20Metadata(_tokensAddresses[i]);

            uint256 tokenAmount = _tokensAmounts[i];

            uint256 fee = tokenAmount.div(100).div(2) ;

            uint256 amount = tokenAmount - fee;

            feeAmount[_tokensAddresses[i]] += fee;
            require(tokenAddress.transferFrom(msg.sender, address(this), tokenAmount));

            amounts[i] = amount;
        }

        return amounts;
    }

    function mint(
        address[] calldata _tokenAddresses,
        uint256[] calldata _tokenAmounts,
        string memory assetURL
    ) public returns (uint256) {
        uint256[] memory amounts = collectFeeAndAmount(_tokenAddresses, _tokenAmounts);

        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, assetURL);

        holders[newItemId] = Holder(msg.sender, _tokenAddresses, amounts, true);

        return newItemId;
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId) internal override {
        address holderAddress = ownerOf(_tokenId);
        Holder memory holder = holders[_tokenId];

        require(holder.flag, "Holder not found");
        require(holderAddress == holder.holderAddress, "Only holder can burn own token");

        for (uint i = 0; i < holder.tokensAddresses.length; i++) {
            IERC20 tokenAddress = IERC20(holder.tokensAddresses[i]);
            uint256 tokenAmount = holder.tokensAmounts[i];

            require(tokenAddress.transfer(msg.sender, tokenAmount));
        }

        if (balances[holderAddress] != 0) {
            balances[holderAddress] -= 1;
        }

        delete holders[_tokenId];
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public view override(ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}