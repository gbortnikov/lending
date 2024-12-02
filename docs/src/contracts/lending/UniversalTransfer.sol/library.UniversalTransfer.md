# UniversalTransfer
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/UniversalTransfer.sol)


## State Variables
### NATIVE

```solidity
address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


## Functions
### universalTransfer


```solidity
function universalTransfer(IERC20 token, address to, uint256 amount) internal;
```

### universalTransferFrom


```solidity
function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal;
```

## Errors
### NativeTransferFailed

```solidity
error NativeTransferFailed();
```

### InsufficientBalance

```solidity
error InsufficientBalance();
```

