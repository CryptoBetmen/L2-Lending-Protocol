// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {AaveOracle} from '../../../contracts/misc/AaveOracle.sol';
import {FallbackOracle} from '../../../contracts/misc/FallbackOracle.sol';
import {AggregatorInterface} from '../../../contracts/dependencies/chainlink/AggregatorInterface.sol';

contract AaveV3OracleProcedure {
  /**
   * @notice Deploys AaveOracle with fallback oracle
   * @param oracleDecimals Number of decimals for oracle prices (typically 8)
   * @param poolAddressesProvider Address of PoolAddressesProvider
   * @param ethUsdPriceFeed Address of Chainlink ETH/USD price feed aggregator
   *                        For Arbitrum Sepolia: 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f
   *                        This is passed from MarketConfig.networkBaseTokenPriceInUsdProxyAggregator
   * @return Address of deployed AaveOracle
   */
  function _deployAaveOracle(
    uint16 oracleDecimals,
    address poolAddressesProvider,
    address ethUsdPriceFeed
  ) internal returns (address) {
    address[] memory emptyArray;

    // Deploy fallback oracle with ETH/USD Chainlink feed (standard Aave approach)
    // For Arbitrum Sepolia, ethUsdPriceFeed should be: 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f
    // This address is configured in K613ArbitrumMarketInput.ARBITRUM_SEPOLIA_ETH_USD_PRICE_FEED
    address fallbackOracle = address(0);
    if (ethUsdPriceFeed != address(0)) {
      fallbackOracle = address(new FallbackOracle(ethUsdPriceFeed));
    }

    address aaveOracle = address(
      new AaveOracle(
        IPoolAddressesProvider(poolAddressesProvider),
        emptyArray,
        emptyArray,
        fallbackOracle,
        address(0), // Base currency: USD (address(0))
        10 ** oracleDecimals
      )
    );

    return aaveOracle;
  }
}
