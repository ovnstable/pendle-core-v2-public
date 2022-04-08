// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "../ISuperComposableYield.sol";
import "./RewardManager.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../libraries/math/FixedPoint.sol";
import "./SCYUtils.sol";

/**
# CONDITIONS TO USE THIS PRESET:
- the token's balance must be static (i.e not increase on its own). Some examples of tokens don't
satisfy this restriction is AaveV2's aToken

*/
abstract contract SCYBase is ERC20, ISuperComposableYield {
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;

    uint8 private immutable _scydecimals;
    uint8 private immutable _assetDecimals;

    mapping(address => uint256) internal lastBalanceOf;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals
    ) ERC20(_name, _symbol) {
        _scydecimals = __scydecimals;
        _assetDecimals = __assetDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function mint(
        address recipient,
        address baseTokenIn,
        uint256 minAmountSCYOut
    ) public virtual override returns (uint256 amountSCYOut) {
        require(isValidBaseToken(baseTokenIn), "invalid base token");

        uint256 amountBaseIn = _afterReceiveToken(baseTokenIn);

        amountSCYOut = _deposit(baseTokenIn, amountBaseIn);

        require(amountSCYOut >= minAmountSCYOut, "insufficient out");

        _mint(recipient, amountSCYOut);
    }

    function redeem(
        address recipient,
        address baseTokenOut,
        uint256 minAmountBaseOut
    ) public virtual override returns (uint256 amountBaseOut) {
        require(isValidBaseToken(baseTokenOut), "invalid base token");

        uint256 amountSCYRedeem = balanceOf(address(this));

        _burn(address(this), amountSCYRedeem);

        amountBaseOut = _redeem(baseTokenOut, amountSCYRedeem);

        require(amountBaseOut >= minAmountBaseOut, "insufficient out");

        IERC20(baseTokenOut).safeTransfer(recipient, amountBaseOut);
        _afterSendToken(baseTokenOut);
    }

    function _deposit(address token, uint256 amountBase)
        internal
        virtual
        returns (uint256 amountSCYOut);

    function _redeem(address token, uint256 amountSCY)
        internal
        virtual
        returns (uint256 amountBaseOut);

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function scyIndexCurrent() public virtual override returns (uint256 res);

    function scyIndexStored() public view virtual override returns (uint256 res);

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _scydecimals;
    }

    function assetDecimals() public view virtual returns (uint8) {
        return _assetDecimals;
    }

    function getBaseTokens() public view virtual override returns (address[] memory res);

    function isValidBaseToken(address token) public view virtual override returns (bool);

    /// @dev token should not be address(this)
    function _afterReceiveToken(address token) internal virtual returns (uint256 res) {
        uint256 curBalance = IERC20(token).balanceOf(address(this));
        res = curBalance - lastBalanceOf[token];
        lastBalanceOf[token] = curBalance;
    }

    /// @dev token should not be address(this)
    function _afterSendToken(address token) internal virtual {
        lastBalanceOf[token] = IERC20(token).balanceOf(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                            TRANSFER HOOKS
    //////////////////////////////////////////////////////////////*/
}