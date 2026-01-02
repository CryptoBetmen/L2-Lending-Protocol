// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV3ConfigEngine as IEngine} from '../../contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from '../../contracts/extensions/v3-config-engine/EngineFlags.sol';

/**
 * @title ArbitrumSepoliaTokensConfig
 * @notice Token configuration for Arbitrum Sepolia testnet
 * @dev Uses default Aave interest rate strategies (no customization)
 *
 * Token addresses for Arbitrum Sepolia:
 * - WETH: 0xC556bA1b7A820bD3b4C76D3FA8944d0E7F0E1F0e (from K613ArbitrumMarketInput)
 * - USDC, USDT, DAI, WBTC: Need to be deployed as TestnetERC20 or use existing testnet tokens
 *   For MVP on testnet, tokens can be deployed using TestnetERC20 contract
 *
 * Chainlink Price Feeds for Arbitrum Sepolia:
 * - ETH/USD: 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f
 * - USDC/USD: 0x8f016Ce412F264E9ada4B1791a20e1de36efF6BF
 * - WBTC/USD: 0xcbb0e9BE7CBC677437B7BD0B63751b06dBe50ccF
 * - USDT/USD, DAI/USD: May not be available on Arbitrum Sepolia, use fallback or deploy mocks
 */
library ArbitrumSepoliaTokensConfig {
  // Chainlink Price Feed addresses for Arbitrum Sepolia
  address internal constant ETH_USD_PRICE_FEED = 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f;
  address internal constant USDC_USD_PRICE_FEED = 0x8f016Ce412F264E9ada4B1791a20e1de36efF6BF;
  address internal constant WBTC_USD_PRICE_FEED = 0xcbb0e9BE7CBC677437B7BD0B63751b06dBe50ccF;
  address internal constant USDT_USD_PRICE_FEED = 0x80EDee6f667eCc9f63a0a6f55578F870651f06A4;
  address internal constant DAI_USD_PRICE_FEED = 0xb113F5A928BCfF189C998ab20d753a47F9dE5A61;
  /**
   * @notice Get token listings configuration for Arbitrum Sepolia
   * @dev Uses standard Aave v3 parameters with default interest rate strategy
   * @param aTokenImpl Address of aToken implementation
   * @param vTokenImpl Address of variableDebtToken implementation
   * @param wethAddress WETH address on Arbitrum Sepolia
   * @return listings Array of token listings with standard Aave parameters
   */

  function getTokenListings(
    address aTokenImpl,
    address vTokenImpl,
    address wethAddress
  ) internal pure returns (IEngine.ListingWithCustomImpl[] memory listings) {
    // Standard Aave v3 parameters (conservative for MVP)
    // LTV: 82.5%, Liquidation Threshold: 86%, Liquidation Bonus: 5%, Reserve Factor: 10%
    uint256 ltv = 82_50;
    uint256 liqThreshold = 86_00;
    uint256 liqBonus = 5_00; // 5% bonus
    uint256 reserveFactor = 10_00; // 10%
    uint256 liqProtocolFee = 10_00; // 10%

    // Default interest rate strategy parameters (will use DEFAULT_INTEREST_RATE_STRATEGY)
    // These are placeholder - actual strategy will be set to default
    IEngine.InterestRateInputData memory defaultRateParams = IEngine.InterestRateInputData({
      optimalUsageRatio: 45_00, // 45% optimal utilization
      baseVariableBorrowRate: 0, // Base rate
      variableRateSlope1: 4_00, // Slope 1: 4%
      variableRateSlope2: 60_00 // Slope 2: 60%
    });

    // Initialize array for 5 tokens: WETH, USDC, USDT, DAI, WBTC
    listings = new IEngine.ListingWithCustomImpl[](5);

    // WETH Configuration
    listings[0] = IEngine.ListingWithCustomImpl({
      base: IEngine.Listing({
        asset: wethAddress,
        assetSymbol: 'WETH',
        priceFeed: ETH_USD_PRICE_FEED,
        rateStrategyParams: defaultRateParams,
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: ltv,
        liqThreshold: liqThreshold,
        liqBonus: liqBonus,
        reserveFactor: reserveFactor,
        supplyCap: 0, // No cap for MVP
        borrowCap: 0, // No cap for MVP
        debtCeiling: 0,
        liqProtocolFee: liqProtocolFee
      }),
      implementations: IEngine.TokenImplementations({aToken: aTokenImpl, vToken: vTokenImpl})
    });

    // USDC Configuration
    listings[1] = IEngine.ListingWithCustomImpl({
      base: IEngine.Listing({
        asset: address(0), // TODO: Deploy TestnetERC20 or use existing USDC on Arbitrum Sepolia
        assetSymbol: 'USDC',
        priceFeed: USDC_USD_PRICE_FEED,
        rateStrategyParams: defaultRateParams,
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: ltv,
        liqThreshold: liqThreshold,
        liqBonus: liqBonus,
        reserveFactor: reserveFactor,
        supplyCap: 0,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: liqProtocolFee
      }),
      implementations: IEngine.TokenImplementations({aToken: aTokenImpl, vToken: vTokenImpl})
    });

    // USDT Configuration
    listings[2] = IEngine.ListingWithCustomImpl({
      base: IEngine.Listing({
        asset: address(0), // TODO: Deploy TestnetERC20 or use existing USDT on Arbitrum Sepolia
        assetSymbol: 'USDT',
        priceFeed: USDT_USD_PRICE_FEED,
        rateStrategyParams: defaultRateParams,
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: ltv,
        liqThreshold: liqThreshold,
        liqBonus: liqBonus,
        reserveFactor: reserveFactor,
        supplyCap: 0,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: liqProtocolFee
      }),
      implementations: IEngine.TokenImplementations({aToken: aTokenImpl, vToken: vTokenImpl})
    });

    // DAI Configuration
    listings[3] = IEngine.ListingWithCustomImpl({
      base: IEngine.Listing({
        asset: address(0), // TODO: Deploy TestnetERC20 or use existing DAI on Arbitrum Sepolia
        assetSymbol: 'DAI',
        priceFeed: DAI_USD_PRICE_FEED,
        rateStrategyParams: defaultRateParams,
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: ltv,
        liqThreshold: liqThreshold,
        liqBonus: liqBonus,
        reserveFactor: reserveFactor,
        supplyCap: 0,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: liqProtocolFee
      }),
      implementations: IEngine.TokenImplementations({aToken: aTokenImpl, vToken: vTokenImpl})
    });

    // WBTC Configuration
    listings[4] = IEngine.ListingWithCustomImpl({
      base: IEngine.Listing({
        asset: address(0), // TODO: Deploy TestnetERC20 or use existing WBTC on Arbitrum Sepolia
        assetSymbol: 'WBTC',
        priceFeed: WBTC_USD_PRICE_FEED,
        rateStrategyParams: defaultRateParams,
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: ltv,
        liqThreshold: liqThreshold,
        liqBonus: liqBonus,
        reserveFactor: reserveFactor,
        supplyCap: 0,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: liqProtocolFee
      }),
      implementations: IEngine.TokenImplementations({aToken: aTokenImpl, vToken: vTokenImpl})
    });
  }

  /**
   * @notice Get standard Aave v3 parameters
   * @return ltv Loan-to-Value ratio (82.5%)
   * @return liqThreshold Liquidation threshold (86%)
   * @return liqBonus Liquidation bonus (5%)
   * @return reserveFactor Reserve factor (10%)
   */
  function getStandardParams()
    internal
    pure
    returns (uint256 ltv, uint256 liqThreshold, uint256 liqBonus, uint256 reserveFactor)
  {
    return (82_50, 86_00, 5_00, 10_00);
  }
}
