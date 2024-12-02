// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract ExtensionWhiteList {
    enum UserStatus {
        NORMAL,
        BANNED,
        PRIVILEGED
    }

    uint256[5] private __gap;

    /**
     * @dev Mapping of user addresses to their respective user status.
     * The user status can be one of NORMAL, BANNED, or PRIVILEGED.
     */
    mapping(address => UserStatus) private _userStatus;
    /**
     * @dev Emitted when the user status of an account is updated.
     * @param account The address of the account whose status is being updated.
     * @param status The new status of the account.
     */
    event UserStatusUpdated(address indexed account, UserStatus status);

    function getUserStatus(address account) public view returns (UserStatus) {
        return _userStatus[account];
    }

    function _updateUserStatus(address account, UserStatus status) internal {
        _userStatus[account] = status;
    }

}
