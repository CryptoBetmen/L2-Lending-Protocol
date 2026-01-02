// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {MarketReport, Roles, MarketConfig, DeployFlags} from '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../../src/contracts/interfaces/IAaveOracle.sol';
import {ACLManager} from '../../src/contracts/protocol/configuration/ACLManager.sol';
import {TestnetERC20} from '../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {WETH9} from '../../src/contracts/dependencies/weth/WETH9.sol';
import {ChainlinkMockAggregator} from '../mocks/ChainlinkMockAggregator.sol';
import {DeployUtils} from '../../src/deployments/contracts/utilities/DeployUtils.sol';
import {AaveV3BatchOrchestration} from '../../src/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol';
import {K613ArbitrumMarketInput} from '../../src/deployments/inputs/K613ArbitrumMarketInput.sol';

/**
 * @title ArbitrumSepoliaDeploymentTest
 * @notice Tests for Arbitrum Sepolia deployment scripts
 * @dev Tests deployment on local anvil network
 */
contract ArbitrumSepoliaDeploymentTest is Test, DeployUtils, K613ArbitrumMarketInput {
  address public deployer;
  address public poolAdmin;
  address public emergencyAdmin;
  address public riskAdmin;

  WETH9 public weth;
  TestnetERC20 public usdc;
  TestnetERC20 public usdt;
  TestnetERC20 public dai;
  TestnetERC20 public wbtc;

  ChainlinkMockAggregator public ethUsdPriceFeed;
  ChainlinkMockAggregator public usdcUsdPriceFeed;
  ChainlinkMockAggregator public wbtcUsdPriceFeed;

  MarketReport public marketReport;

  function setUp() public {
    deployer = address(this);
    poolAdmin = makeAddr('poolAdmin');
    emergencyAdmin = makeAddr('emergencyAdmin');
    riskAdmin = makeAddr('riskAdmin');

    // Deploy mock tokens
    weth = new WETH9();
    usdc = new TestnetERC20('USD Coin', 'USDC', 6, deployer);
    usdt = new TestnetERC20('Tether USD', 'USDT', 6, deployer);
    dai = new TestnetERC20('Dai Stablecoin', 'DAI', 18, deployer);
    wbtc = new TestnetERC20('Wrapped Bitcoin', 'WBTC', 8, deployer);

    // Deploy mock Chainlink price feeds
    ethUsdPriceFeed = new ChainlinkMockAggregator(8);
    ethUsdPriceFeed.setLatestAnswer(2000e8); // $2000 per ETH

    usdcUsdPriceFeed = new ChainlinkMockAggregator(8);
    usdcUsdPriceFeed.setLatestAnswer(1e8); // $1 per USDC

    wbtcUsdPriceFeed = new ChainlinkMockAggregator(8);
    wbtcUsdPriceFeed.setLatestAnswer(40000e8); // $40000 per WBTC

    // Note: In real deployment, these would be actual Chainlink feeds
    // For testing, we use mocks

    // Mint tokens to deployer
    usdc.mint(deployer, 1000000e6);
    usdt.mint(deployer, 1000000e6);
    dai.mint(deployer, 1000000e18);
    wbtc.mint(deployer, 10e8);
  }

  /// @notice Test market deployment
  function test1DeployMarket() public {
    // Setup roles and config
    Roles memory roles = Roles({
      marketOwner: deployer,
      poolAdmin: poolAdmin,
      emergencyAdmin: emergencyAdmin
    });

    MarketConfig memory config;
    DeployFlags memory flags;
    MarketReport memory deployedContracts;

    // Get market input from K613ArbitrumMarketInput
    (roles, config, flags, deployedContracts) = _getMarketInput(deployer);

    // Override WETH address with our mock
    config.wrappedNativeToken = address(weth);

    // Override price feeds with mocks
    config.networkBaseTokenPriceInUsdProxyAggregator = address(ethUsdPriceFeed);
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = address(ethUsdPriceFeed);

    // Deploy market using orchestration
    marketReport = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    // Verify core contracts are deployed
    assertNotEq(
      marketReport.poolAddressesProvider,
      address(0),
      'PoolAddressesProvider not deployed'
    );
    assertNotEq(marketReport.poolProxy, address(0), 'PoolProxy not deployed');
    assertNotEq(
      marketReport.poolConfiguratorProxy,
      address(0),
      'PoolConfiguratorProxy not deployed'
    );
    assertNotEq(marketReport.aclManager, address(0), 'ACLManager not deployed');
    assertNotEq(marketReport.aaveOracle, address(0), 'AaveOracle not deployed');

    // Verify contracts have code
    assertGt(marketReport.poolProxy.code.length, 0, 'PoolProxy has no code');
    assertGt(
      marketReport.poolConfiguratorProxy.code.length,
      0,
      'PoolConfiguratorProxy has no code'
    );

    // Verify Pool is linked to Provider
    IPoolAddressesProvider provider = IPoolAddressesProvider(marketReport.poolAddressesProvider);
    assertEq(address(provider.getPool()), marketReport.poolProxy, 'Pool address mismatch');

    // Verify Provider is linked to Pool
    IPool pool = IPool(marketReport.poolProxy);
    assertEq(address(pool.ADDRESSES_PROVIDER()), address(provider), 'Provider address mismatch');

    // Market deployment successful
  }

  function test2DeployTokens() public {
    console.log('=== Testing Token Deployment ===');

    // Tokens are already deployed in setUp()
    // Verify tokens are deployed
    assertNotEq(address(usdc), address(0), 'USDC not deployed');
    assertNotEq(address(usdt), address(0), 'USDT not deployed');
    assertNotEq(address(dai), address(0), 'DAI not deployed');
    assertNotEq(address(wbtc), address(0), 'WBTC not deployed');

    // Verify token balances
    assertEq(usdc.balanceOf(deployer), 1000000e6, 'USDC balance incorrect');
    assertEq(usdt.balanceOf(deployer), 1000000e6, 'USDT balance incorrect');
    assertEq(dai.balanceOf(deployer), 1000000e18, 'DAI balance incorrect');
    assertEq(wbtc.balanceOf(deployer), 10e8, 'WBTC balance incorrect');

    console.log('Token deployment successful!');
    console.log('USDC:', address(usdc));
    console.log('USDT:', address(usdt));
    console.log('DAI:', address(dai));
    console.log('WBTC:', address(wbtc));
  }

  function test3ListTokens() public {
    console.log('=== Testing Token Listing ===');
    console.log('Note: Token listing requires ConfigEngine and payload execution');
    console.log('This test verifies that tokens are ready for listing');

    // Verify tokens exist
    assertNotEq(address(weth), address(0), 'WETH not deployed');
    assertNotEq(address(usdc), address(0), 'USDC not deployed');
    assertNotEq(address(usdt), address(0), 'USDT not deployed');
    assertNotEq(address(dai), address(0), 'DAI not deployed');
    assertNotEq(address(wbtc), address(0), 'WBTC not deployed');

    console.log('All tokens ready for listing');
  }

  function test4ValidateDeployment() public {
    console.log('=== Testing Deployment Validation ===');

    // Deploy market first (reuse test1 logic)
    Roles memory roles = Roles({
      marketOwner: deployer,
      poolAdmin: poolAdmin,
      emergencyAdmin: emergencyAdmin
    });

    MarketConfig memory config;
    DeployFlags memory flags;
    MarketReport memory deployedContracts;

    (roles, config, flags, deployedContracts) = _getMarketInput(deployer);
    config.wrappedNativeToken = address(weth);
    config.networkBaseTokenPriceInUsdProxyAggregator = address(ethUsdPriceFeed);
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = address(ethUsdPriceFeed);

    marketReport = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    // Validate core contracts
    assertNotEq(marketReport.poolAddressesProvider, address(0), 'Provider is zero');
    assertNotEq(marketReport.poolProxy, address(0), 'Pool is zero');
    assertNotEq(marketReport.aclManager, address(0), 'ACLManager is zero');
    assertNotEq(marketReport.aaveOracle, address(0), 'Oracle is zero');

    // Validate contracts have code
    assertGt(marketReport.poolProxy.code.length, 0, 'Pool has no code');
    assertGt(marketReport.poolConfiguratorProxy.code.length, 0, 'Configurator has no code');

    // Validate Oracle
    IAaveOracle oracle = IAaveOracle(marketReport.aaveOracle);
    address baseCurrency = oracle.BASE_CURRENCY();
    assertNotEq(baseCurrency, address(0), 'Base currency is zero');

    console.log('Deployment validation successful!');
  }

  function test5PostDeploySetup() public {
    console.log('=== Testing Post-Deploy Setup ===');

    // Deploy market
    Roles memory roles = Roles({
      marketOwner: deployer,
      poolAdmin: poolAdmin,
      emergencyAdmin: emergencyAdmin
    });

    MarketConfig memory config;
    DeployFlags memory flags;
    MarketReport memory deployedContracts;

    (roles, config, flags, deployedContracts) = _getMarketInput(deployer);
    config.wrappedNativeToken = address(weth);
    config.networkBaseTokenPriceInUsdProxyAggregator = address(ethUsdPriceFeed);
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = address(ethUsdPriceFeed);

    marketReport = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    // Setup roles
    ACLManager aclManager = ACLManager(marketReport.aclManager);

    // Verify ACLManager is set in Provider
    IPoolAddressesProvider provider = IPoolAddressesProvider(marketReport.poolAddressesProvider);
    assertEq(address(provider.getACLManager()), address(aclManager), 'ACLManager not set');

    console.log('Post-deploy setup validation successful!');
  }

  function test6FullDeploymentFlow() public {
    console.log('=== Testing Full Deployment Flow ===');

    // Step 1: Deploy market
    Roles memory roles = Roles({
      marketOwner: deployer,
      poolAdmin: poolAdmin,
      emergencyAdmin: emergencyAdmin
    });

    MarketConfig memory config;
    DeployFlags memory flags;
    MarketReport memory deployedContracts;

    (roles, config, flags, deployedContracts) = _getMarketInput(deployer);
    config.wrappedNativeToken = address(weth);
    config.networkBaseTokenPriceInUsdProxyAggregator = address(ethUsdPriceFeed);
    config.marketReferenceCurrencyPriceInUsdProxyAggregator = address(ethUsdPriceFeed);

    marketReport = AaveV3BatchOrchestration.deployAaveV3(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    // Step 2: Verify market is functional
    IPool pool = IPool(marketReport.poolProxy);
    IPoolAddressesProvider provider = IPoolAddressesProvider(marketReport.poolAddressesProvider);

    assertEq(address(pool.ADDRESSES_PROVIDER()), address(provider), 'Pool-Provider link broken');

    // Step 3: Verify Oracle
    IAaveOracle oracle = IAaveOracle(marketReport.aaveOracle);
    address baseCurrency = oracle.BASE_CURRENCY();
    assertNotEq(baseCurrency, address(0), 'Oracle not configured');

    // Step 4: Verify ACL
    ACLManager aclManager = ACLManager(marketReport.aclManager);
    assertEq(address(provider.getACLManager()), address(aclManager), 'ACL not set');

    console.log('Full deployment flow test passed!');
    console.log('All core contracts deployed and configured correctly');
  }
}
