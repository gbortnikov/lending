# ExtensionWhiteList
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/c7db5af1f45d7a5d76d56fec25448244aa8d00e7/contracts/extensions/ExtensionWhiteList.sol)


## State Variables
### __gap

```solidity
uint256[5] private __gap;
```


### _userStatus
*Mapping of user addresses to their respective user status.
The user status can be one of NORMAL, BANNED, or PRIVILEGED.*


```solidity
mapping(address => UserStatus) private _userStatus;
```


## Functions
### getUserStatus


```solidity
function getUserStatus(address account) public view returns (UserStatus);
```

### _updateUserStatus


```solidity
function _updateUserStatus(address account, UserStatus status) internal;
```

## Events
### UserStatusUpdated
*Emitted when the user status of an account is updated.*


```solidity
event UserStatusUpdated(address indexed account, UserStatus status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account whose status is being updated.|
|`status`|`UserStatus`|The new status of the account.|

## Enums
### UserStatus

```solidity
enum UserStatus {
    NORMAL,
    BANNED,
    PRIVILEGED
}
```

