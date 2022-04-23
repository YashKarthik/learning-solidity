//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./UniswapV2Library.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol";

contract Arbitrage {
    address public factory; // uniswap factory
    uint constant deadline = 10 days;
    IUniswapV2Router02 public sushiRouter;
    address owner;

    constructor(
        address _factory,
        address _sushiRouter
    ) public {
        factory = _factory;
        sushiRouter = IUniswapV2Router02(_sushiRouter);
        owner = msg.sender;
    }

    // The amount will be non-zero only for the token we wanna borrow
    function initArbitrage(
        address _token0,
        address _token1,
        uint _amount0,
        uint _amount1
    ) external {
        address pairAddress = IUniswapV2Factory(factory)
                               .getPair(_token0, _token1);
        
        require(pairAddress != address(0), "Pool doesn't exist");

        IUniswapV2Pair(pairAddress).swap(
            _amount0,
            _amount1,
            address(this),
            bytes("non empty for flash loan")
        );
    }

    function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external {
        address[] memory path = new address[](2);
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(
            msg.sender == UniswapV2Library.pairFor(
                factory,
                token0,
                token1
            ),
            "Unauthorized"
        );

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);

        token.approve(address(sushiRouter), amountToken);

        uint amountRequired = UniswapV2Library.getAmountsIn(
            factory,
            amountToken,
            path
        )[0];

        uint amountReceived = sushiRouter.swapExactTokensForTokens(
            amountToken,
            amountRequired,
            path,
            msg.sender,
            deadline
        )[1];

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        otherToken.transfer(msg.sender, amountRequired);
        otherToken.transfer(owner, amountReceived - amountRequired);
    }
}
