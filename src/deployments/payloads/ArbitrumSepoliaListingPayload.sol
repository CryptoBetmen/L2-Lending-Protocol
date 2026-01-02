// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3Payload} from '../../contracts/extensions/v3-config-engine/AaveV3Payload.sol';
import {IAaveV3ConfigEngine as IEngine} from '../../contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from '../../contracts/extensions/v3-config-engine/EngineFlags.sol';
import {ArbitrumSepoliaTokensConfig} from '../inputs/ArbitrumSepoliaTokensConfig.sol';
import {MarketReport} from '../interfaces/IMarketReportTypes.sol';
import {ACLManager} from '../../contracts/protocol/configuration/ACLManager.sol';

/**
 * @title ArbitrumSepoliaListingPayload
 * @notice Payload contract for listing tokens on Arbitrum Sepolia testnet
 * @dev This payload uses ArbitrumSepoliaTokensConfig to list:
 * - WETH
 * - USDC
 * - USDT
 * - DAI
 * - WBTC
 *
 * Token addresses must be provided in constructor.
 * After execution, renounces POOL_ADMIN role for security.
 */
contract ArbitrumSepoliaListingPayload is AaveV3Payload {
  bytes32 public constant POOL_ADMIN_ROLE_ID =
    0x12ad05bde78c5ab75238ce885307f96ecd482bb402ef831f99e7018a0f169b7b;

  MarketReport public REPORT;
  address public immutable ATOKEN_IMPL;
  address public immutable VTOKEN_IMPL;
  address public immutable WETH_ADDRESS;
  address public immutable USDC_ADDRESS;
  address public immutable USDT_ADDRESS;
  address public immutable DAI_ADDRESS;
  address public immutable WBTC_ADDRESS;

  /**
   * @notice Constructor
   * @param engine ConfigEngine address
   * @param report MarketReport with deployed contract addresses
   * @param wethAddress WETH address on Arbitrum Sepolia
   * @param usdcAddress USDC address on Arbitrum Sepolia (or TestnetERC20)
   * @param usdtAddress USDT address on Arbitrum Sepolia (or TestnetERC20)
   * @param daiAddress DAI address on Arbitrum Sepolia (or TestnetERC20)
   * @param wbtcAddress WBTC address on Arbitrum Sepolia (or TestnetERC20)
   */
  constructor(
    IEngine engine,
    MarketReport memory report,
    address wethAddress,
    address usdcAddress,
    address usdtAddress,
    address daiAddress,
    address wbtcAddress
  ) AaveV3Payload(engine) {
    REPORT = report;
    ATOKEN_IMPL = report.aToken;
    VTOKEN_IMPL = report.variableDebtToken;
    WETH_ADDRESS = wethAddress;
    USDC_ADDRESS = usdcAddress;
    USDT_ADDRESS = usdtAddress;
    DAI_ADDRESS = daiAddress;
    WBTC_ADDRESS = wbtcAddress;
  }

  /**
   * @notice Returns token listings with custom implementations
   * @dev Uses ArbitrumSepoliaTokensConfig and updates token addresses
   * @return listings Array of token listings
   */
  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    // Get base listings from config
    IEngine.ListingWithCustomImpl[] memory listings = ArbitrumSepoliaTokensConfig.getTokenListings(
      ATOKEN_IMPL,
      VTOKEN_IMPL,
      WETH_ADDRESS
    );

    // Update token addresses (config has address(0) for tokens that need to be deployed)
    // listings[0] = WETH (already correct)
    listings[1].base.asset = USDC_ADDRESS; // USDC
    listings[2].base.asset = USDT_ADDRESS; // USDT
    listings[3].base.asset = DAI_ADDRESS; // DAI
    listings[4].base.asset = WBTC_ADDRESS; // WBTC

    return listings;
  }

  /**
   * @notice Returns pool context for deployment
   * @return Pool context with network information
   */
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Arbitrum Sepolia', networkAbbreviation: 'ArbSep'});
  }

  /**
   * @notice Post-execution hook
   * @dev Renounces POOL_ADMIN role after listing for security
   */
  function _postExecute() internal override {
    ACLManager(REPORT.aclManager).renounceRole(POOL_ADMIN_ROLE_ID, address(this));
  }
}
