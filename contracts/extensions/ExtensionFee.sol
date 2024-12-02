// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract ExtensionFee {
    uint256 internal _fee;
    uint256 internal _totalTax;
    uint256[5] private __gap;

    event SetFee(uint256 fee);

    /**
     * The getTax function is a view function that returns the value of the _totalTax variable,
     * which represents the total tax amount calculated by the contract.
     */
    function getTax() external view returns (uint256 tax) {
        return _totalTax;
    }

    function getFee() external view returns (uint256 fee) {
        return (_fee);
    }

    function _setFee(uint256 fee) internal {
        _fee = fee;
        emit SetFee(fee);
    }

    /**
     * This function calculates the tax amount based on the given fee and amount,
     * updates the total tax amount, and returns the calculated tax.
     * @param fee The fee percentage to be applied.
     * @param amount The amount on which the fee will be calculated.
     */
    function _takeFee(uint256 fee, uint256 amount) internal returns (uint256 tax) {
        tax = (fee * amount) / 1e8;
        _totalTax += tax;

        return tax;
    }
}
