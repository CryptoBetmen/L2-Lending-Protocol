// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import 'forge-std/StdJson.sol';
import {IAaveV3ConfigEngine} from '../src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {ArbitrumSepoliaListingPayload} from '../src/deployments/payloads/ArbitrumSepoliaListingPayload.sol';
import {MarketReport} from '../src/deployments/interfaces/IMarketReportTypes.sol';
import {DeployUtils} from '../src/deployments/contracts/utilities/DeployUtils.sol';

/**
 * @title ListArbitrumSepoliaTokens
 * @notice Lists tokens on deployed Aave v3 market using ArbitrumSepoliaListingPayload
 * @dev This script:
 * 1. Loads market deployment report from /reports
 * 2. Deploys ArbitrumSepoliaListingPayload
 * 3. Executes payload to list tokens
 *
 * Prerequisites:
 * - Market must be deployed (run DeployArbitrumSepoliaMarket first)
 * - Tokens must be deployed (run DeployArbitrumSepoliaTokens first)
 * - Set environment variables:
 *   - WETH_ADDRESS: WETH address on Arbitrum Sepolia
 *   - USDC_ADDRESS: USDC token address
 *   - USDT_ADDRESS: USDT token address
 *   - DAI_ADDRESS: DAI token address
 *   - WBTC_ADDRESS: WBTC token address
 *
 * Usage:
 * forge script scripts/ListArbitrumSepoliaTokens.sol:ListArbitrumSepoliaTokens \
 *   --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --slow
 */
contract ListArbitrumSepoliaTokens is Script, DeployUtils {
  using stdJson for string;

  function run() external {
    console.log('Loading market deployment report...');

    // Load market report from JSON
    string memory jsonReport = vm.readFile('./reports/market-report.json');
    MarketReport memory report = MarketReport({
      poolAddressesProviderRegistry: jsonReport.readAddress('.poolAddressesProviderRegistry'),
      poolAddressesProvider: jsonReport.readAddress('.poolAddressesProvider'),
      poolProxy: jsonReport.readAddress('.poolProxy'),
      poolImplementation: jsonReport.readAddress('.poolImplementation'),
      poolConfiguratorProxy: jsonReport.readAddress('.poolConfiguratorProxy'),
      poolConfiguratorImplementation: jsonReport.readAddress('.poolConfiguratorImplementation'),
      protocolDataProvider: jsonReport.readAddress('.protocolDataProvider'),
      aaveOracle: jsonReport.readAddress('.aaveOracle'),
      defaultInterestRateStrategy: jsonReport.readAddress('.defaultInterestRateStrategy'),
      priceOracleSentinel: jsonReport.readAddress('.priceOracleSentinel'),
      aclManager: jsonReport.readAddress('.aclManager'),
      treasury: jsonReport.readAddress('.treasury'),
      treasuryImplementation: jsonReport.readAddress('.treasuryImplementation'),
      wrappedTokenGateway: jsonReport.readAddress('.wrappedTokenGateway'),
      walletBalanceProvider: jsonReport.readAddress('.walletBalanceProvider'),
      uiIncentiveDataProvider: jsonReport.readAddress('.uiIncentiveDataProvider'),
      uiPoolDataProvider: jsonReport.readAddress('.uiPoolDataProvider'),
      paraSwapLiquiditySwapAdapter: jsonReport.readAddress('.paraSwapLiquiditySwapAdapter'),
      paraSwapRepayAdapter: jsonReport.readAddress('.paraSwapRepayAdapter'),
      paraSwapWithdrawSwapAdapter: jsonReport.readAddress('.paraSwapWithdrawSwapAdapter'),
      l2Encoder: jsonReport.readAddress('.l2Encoder'),
      aToken: jsonReport.readAddress('.aToken'),
      variableDebtToken: jsonReport.readAddress('.variableDebtToken'),
      emissionManager: jsonReport.readAddress('.emissionManager'),
      rewardsControllerImplementation: jsonReport.readAddress('.rewardsControllerImplementation'),
      rewardsControllerProxy: jsonReport.readAddress('.rewardsControllerProxy'),
      configEngine: jsonReport.readAddress('.configEngine'),
      transparentProxyFactory: jsonReport.readAddress('.transparentProxyFactory'),
      staticATokenFactoryImplementation: jsonReport.readAddress(
        '.staticATokenFactoryImplementation'
      ),
      staticATokenFactoryProxy: jsonReport.readAddress('.staticATokenFactoryProxy'),
      staticATokenImplementation: jsonReport.readAddress('.staticATokenImplementation'),
      revenueSplitter: jsonReport.readAddress('.revenueSplitter'),
      dustBin: jsonReport.readAddress('.dustBin'),
      emptyImplementation: jsonReport.readAddress('.emptyImplementation')
    });

    console.log('Pool Addresses Provider:', report.poolAddressesProvider);
    console.log('Pool Proxy:', report.poolProxy);

    // Get token addresses from environment or use defaults
    address weth = vm.envOr('WETH_ADDRESS', address(0xC556bA1b7A820bD3b4C76D3FA8944d0E7F0E1F0e));
    address usdc = vm.envOr('USDC_ADDRESS', address(0));
    address usdt = vm.envOr('USDT_ADDRESS', address(0));
    address dai = vm.envOr('DAI_ADDRESS', address(0));
    address wbtc = vm.envOr('WBTC_ADDRESS', address(0));

    require(weth != address(0), 'WETH_ADDRESS not set');
    require(usdc != address(0), 'USDC_ADDRESS not set');
    require(usdt != address(0), 'USDT_ADDRESS not set');
    require(dai != address(0), 'DAI_ADDRESS not set');
    require(wbtc != address(0), 'WBTC_ADDRESS not set');

    console.log('\nToken addresses:');
    console.log('WETH:', weth);
    console.log('USDC:', usdc);
    console.log('USDT:', usdt);
    console.log('DAI:', dai);
    console.log('WBTC:', wbtc);

    // Get ConfigEngine address from report or environment
    address configEngine = report.configEngine;
    if (configEngine == address(0)) {
      configEngine = vm.envOr('CONFIG_ENGINE_ADDRESS', address(0));
      require(configEngine != address(0), 'CONFIG_ENGINE_ADDRESS must be set or in report');
    }

    console.log('\nDeploying ArbitrumSepoliaListingPayload...');

    vm.startBroadcast();

    // Deploy payload
    ArbitrumSepoliaListingPayload payload = new ArbitrumSepoliaListingPayload(
      IAaveV3ConfigEngine(configEngine),
      report,
      weth,
      usdc,
      usdt,
      dai,
      wbtc
    );

    console.log('Payload deployed at:', address(payload));

    // Execute payload
    console.log('\nExecuting payload to list tokens...');
    payload.execute();

    vm.stopBroadcast();

    console.log('\n=== Token Listing Complete ===');
    console.log('Tokens listed successfully!');
  }
}
