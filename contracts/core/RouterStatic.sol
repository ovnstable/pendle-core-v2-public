// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../interfaces/IPRouterStatic.sol";
import "../interfaces/IPMarket.sol";
import "../interfaces/IPYieldContractFactory.sol";
import "../interfaces/IPMarketFactory.sol";
import "../libraries/math/MarketMathAux.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RouterStatic is IPRouterStatic {
    using MarketMathCore for MarketState;
    using MarketMathAux for MarketState;
    using Math for uint256;
    using Math for int256;
    using LogExpMath for int256;

    IPYieldContractFactory public immutable yieldContractFactory;
    IPMarketFactory public immutable marketFactory;

    constructor(IPYieldContractFactory _yieldContractFactory, IPMarketFactory _marketFactory) {
        yieldContractFactory = _yieldContractFactory;
        marketFactory = _marketFactory;
    }

    function addLiquidityStatic(
        address market,
        uint256 scyDesired,
        uint256 ptDesired
    )
        external
        returns (
            uint256 netLpOut,
            uint256 scyUsed,
            uint256 ptUsed
        )
    {
        MarketState memory state = IPMarket(market).readState(false);
        (, netLpOut, scyUsed, ptUsed) = state.addLiquidity(
            scyIndex(market),
            scyDesired,
            ptDesired,
            false
        );
    }

    function removeLiquidityStatic(address market, uint256 lpToRemove)
        external
        view
        returns (uint256 netScyOut, uint256 netPtOut)
    {
        MarketState memory state = IPMarket(market).readState(false);
        (netScyOut, netPtOut) = state.removeLiquidity(lpToRemove, false);
    }

    function swapPtForScyStatic(address market, uint256 exactPtIn)
        external
        returns (uint256 netScyOut, uint256 netScyFee)
    {
        MarketState memory state = IPMarket(market).readState(false);
        (netScyOut, netScyFee) = state.swapExactPtForScy(
            scyIndex(market),
            exactPtIn,
            block.timestamp,
            false
        );
    }

    function swapScyForPtStatic(address market, uint256 exactPtOut)
        external
        returns (uint256 netScyIn, uint256 netScyFee)
    {
        MarketState memory state = IPMarket(market).readState(false);
        (netScyIn, netScyFee) = state.swapScyForExactPt(
            scyIndex(market),
            exactPtOut,
            block.timestamp,
            false
        );
    }

    function scyIndex(address market) public returns (SCYIndex index) {
        return SCYIndexLib.newIndex(IPMarket(market).SCY());
    }

    function getPtImpliedYield(address market) external view returns (int256) {
        MarketState memory state = IPMarket(market).readState(false);

        int256 lnImpliedRate = (state.lastLnImpliedRate).Int();
        return lnImpliedRate.exp();
    }

    function getPendleTokenType(address token)
        external
        view
        returns (
            bool isPT,
            bool isYT,
            bool isMarket
        )
    {
        if (yieldContractFactory.isPT(token)) isPT = true;
        else if (yieldContractFactory.isYT(token)) isYT = true;
        else if (marketFactory.isValidMarket(token)) isMarket = true;
    }
}
