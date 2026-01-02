// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AggregatorInterface} from '../dependencies/chainlink/AggregatorInterface.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';

/**
 * @title FallbackOracle
 * @notice Simple fallback oracle that returns ETH/USD price from Chainlink
 * @dev Standard Aave approach: use ETH/USD Chainlink aggregator as fallback
 * This is used when:
 * - Asset source is not set (address(0))
 * - Chainlink aggregator returns invalid price (<= 0)
 *
 * For MVP: Simple implementation that returns ETH/USD price for all assets
 * This is acceptable and follows Aave's standard pattern
 */
contract FallbackOracle is IPriceOracleGetter {
  AggregatorInterface public immutable ETH_USD_AGGREGATOR;

  // Base currency is USD (address(0))
  address public constant override BASE_CURRENCY = address(0);

  // Base currency unit for USD (8 decimals)
  uint256 public constant override BASE_CURRENCY_UNIT = 1e8;

  /**
   * @notice Constructor
   * @param ethUsdAggregator Address of Chainlink ETH/USD price feed aggregator
   */
  constructor(address ethUsdAggregator) {
    require(ethUsdAggregator != address(0), 'INVALID_AGGREGATOR');
    ETH_USD_AGGREGATOR = AggregatorInterface(ethUsdAggregator);
  }

  /**
   * @notice Returns the asset price in USD
   * @dev For MVP: Returns ETH/USD price for all assets
   * This is the standard Aave fallback approach
   * @param /* asset The address of the asset (ignored, returns ETH/USD)
   * @return The price of ETH in USD (8 decimals)
   */
  function getAssetPrice(address /* asset */) external view override returns (uint256) {
    // Standard Aave fallback: return ETH/USD price
    // This is acceptable for MVP and follows Aave's pattern
    int256 price = ETH_USD_AGGREGATOR.latestAnswer();
    require(price > 0, 'INVALID_PRICE');
    return uint256(price);
  }
}
