# ExtensionFee

## State Variables
### _fee

```solidity
uint256 internal _fee;
```


### _totalTax

```solidity
uint256 internal _totalTax;
```


## Functions
### getTax

The getTax function is a view function that returns the value of the _totalTax variable,
which represents the total tax amount calculated by the contract.


```solidity
function getTax() external view returns (uint256 tax);
```

### getFee


```solidity
function getFee() external view returns (uint256 fee);
```

### _setFee


```solidity
function _setFee(uint256 fee) internal;
```

### _takeFee

This function calculates the tax amount based on the given fee and amount,
updates the total tax amount, and returns the calculated tax.


```solidity
function _takeFee(uint256 fee, uint256 amount) internal returns (uint256 tax);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|The fee percentage to be applied.|
|`amount`|`uint256`|The amount on which the fee will be calculated.|


## Events
### SetFee

```solidity
event SetFee(uint256 fee);
```

