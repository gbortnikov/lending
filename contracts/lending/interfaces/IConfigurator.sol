// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IConfigurator {
    event NewPool(address token0, address token1, address pool);
    event PoolPaused(address pool, bool status);
    event PoolHealthRewardConfigUpdated(
        address pool,
        uint256 minHealthPercent,
        uint256 liquidateHealthPercent,
        uint128 healthPurpose,
        uint256 rewardLiquidatorPercent,
        uint256 rewardPlatformPercent
    );

    event PoolConfigUpdated(address pool, address dataFeed, uint256 acceptableTimeInterval);

    event PoolTokenConfigUpdated(
        address pool,
        address dataFeed,
        uint256 acceptableTimeInterval,
        address dataFeedTokenUsd
    );

    event PoolBorrowRateUpdated(address pool, uint256 borrowRatePerYear);
    event ImplementationPoolUpdated(address impl);
    event PoolRewardConfigUpdated(address pool, uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent);
    event PoolRewardUpdated(address pool, address reward, uint256 rewardAmount);
    event AdapterUpdated(address adapter);
    event AdapterPaused(address adapter, bool status);
    event TreasureUpdated(address treasure);
    event Deposit(address token, address account, uint256 amount);
    event Withdraw(address token, address account, uint256 amount);
    event WithdrawTax(address token, address account, uint256 amount);
    event PoolExtraRewardUpdated(address pool, uint256 extraReward);
    event ReplenishLosses(address token, address account, uint256 amount);

    error InvalidPair(address token0, address token1);
    error ZeroAddress();

    function isToken(address token) external view returns (bool);

    // ------------------------ START POOL SETTINGS ------------------------

    function newPool(address token0, address token1, address chainlinkAggregator) external returns (address pool);

    function pausePool(address pool) external;

    function unpausePool(address pool) external;

    function setHealthRewardConfig(
        address pool,
        uint256 newMinHealthPercent,
        uint256 newLiquidateHealthPercent,
        uint128 newHealthPurpose,
        uint256 newRewardLiquidatorPercent,
        uint256 newRewardPlatformPercent
    ) external;

    function setPoolConfig(address pool, address newDataFeed, uint256 newAcceptableTimeInterval) external;

    function setPoolBorrowRate(address pool, uint256 borrowRatePerYear) external;

    function setPoolExtraReward(address pool, uint256 extraReward) external;

    function setImplementationPool(address impl) external;

    function setPoolMinLoan(address pool, uint256 newMinLoan) external;

    function getImplementationPool() external view returns (address);

    function getPool(address token0, address token1) external view returns (address);

    // ------------------------ END POOL SETTINGS ------------------------

    // ------------------------ START ADAPTER SETTINGS ------------------------

    function setAdapter(address adapter) external;

    function pauseAdapter() external;

    function unpauseAdapter() external;

    function setAdapterEntryFee(uint256 fee) external;

    function getAdapter() external view returns (address);

    // ------------------------ END ADAPTER SETTINGS ------------------------

    // ------------------------ START TREASURE SETTINGS ------------------------

    function setTreasure(address payable treasure) external;

    function refund(address token, uint256 amount) external payable;

    function investCollateral(address token, address to, uint256 amount) external;

    function withdrawTaxBorrow(address token, address to, uint256 amount) external;

    function withdrawTaxLiquidate(address token, address to, uint256 amount) external;

    function withdrawLiquidateCollateral(address token, address to, uint256 amount) external;

    // ------------------------ END TREASURE SETTINGS ------------------------
}
