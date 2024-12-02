# INonfungiblePositionManager
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/c7db5af1f45d7a5d76d56fec25448244aa8d00e7/contracts/mock/INonfungiblePositionManager.sol)


## Functions
### mint


```solidity
function mint(MintParams calldata params)
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
```

### createAndInitializePoolIfNecessary


```solidity
function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96)
    external
    payable
    returns (address pool);
```

## Structs
### MintParams

```solidity
struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
}
```

