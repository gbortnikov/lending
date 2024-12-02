# IUniswapV3Pool
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/7f46b1c539a4b56f94eced3cede2e793666e98aa/contracts/mock/IUniswapV3Pool.sol)


## Functions
### slot0


```solidity
function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
```

### tickSpacing


```solidity
function tickSpacing() external view returns (int24 tickSpacing);
```

