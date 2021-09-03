// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface ICollateralFacet {
        function collaterals(uint256 _hauntId)
        external
        view
        returns (address[] memory collaterals_);
}