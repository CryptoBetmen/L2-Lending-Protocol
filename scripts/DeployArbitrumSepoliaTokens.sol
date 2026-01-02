// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import 'forge-std/StdJson.sol';
import {TestnetERC20} from '../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {IMetadataReporter} from '../src/deployments/interfaces/IMetadataReporter.sol';
import {DeployUtils} from '../src/deployments/contracts/utilities/DeployUtils.sol';

/**
 * @title DeployArbitrumSepoliaTokens
 * @notice Deploys TestnetERC20 tokens for Arbitrum Sepolia testnet
 * @dev Deploys USDC, USDT, DAI, WBTC as TestnetERC20 tokens
 *      Saves token addresses to JSON report
 *
 * Token specifications:
 * - USDC: 6 decimals
 * - USDT: 6 decimals
 * - DAI: 18 decimals
 * - WBTC: 8 decimals
 *
 * Usage:
 * forge script scripts/DeployArbitrumSepoliaTokens.sol:DeployArbitrumSepoliaTokens \
 *   --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify \
 *   --slow
 */
contract DeployArbitrumSepoliaTokens is Script, DeployUtils {
  using stdJson for string;

  // Token owner (will be msg.sender)
  address public tokenOwner;

  // Deployed token addresses
  address public usdc;
  address public usdt;
  address public dai;
  address public wbtc;

  struct TokenReport {
    address usdc;
    address usdt;
    address dai;
    address wbtc;
    address weth; // Arbitrum Sepolia WETH (constant)
    address deployer;
    uint256 timestamp;
  }

  function run() external {
    tokenOwner = msg.sender;

    console.log('Deploying TestnetERC20 tokens for Arbitrum Sepolia');
    console.log('Token owner:', tokenOwner);

    vm.startBroadcast();

    // Deploy USDC (6 decimals)
    usdc = address(new TestnetERC20('USD Coin', 'USDC', 6, tokenOwner));
    console.log('USDC deployed at:', usdc);

    // Deploy USDT (6 decimals)
    usdt = address(new TestnetERC20('Tether USD', 'USDT', 6, tokenOwner));
    console.log('USDT deployed at:', usdt);

    // Deploy DAI (18 decimals)
    dai = address(new TestnetERC20('Dai Stablecoin', 'DAI', 18, tokenOwner));
    console.log('DAI deployed at:', dai);

    // Deploy WBTC (8 decimals)
    wbtc = address(new TestnetERC20('Wrapped Bitcoin', 'WBTC', 8, tokenOwner));
    console.log('WBTC deployed at:', wbtc);

    vm.stopBroadcast();

    // WETH address on Arbitrum Sepolia (constant)
    address weth = 0xC556bA1b7A820bD3b4C76D3FA8944d0E7F0E1F0e;

    console.log('\n=== Deployment Summary ===');
    console.log('WETH:', weth);
    console.log('USDC:', usdc);
    console.log('USDT:', usdt);
    console.log('DAI:', dai);
    console.log('WBTC:', wbtc);

    // Save to JSON report
    TokenReport memory report = TokenReport({
      usdc: usdc,
      usdt: usdt,
      dai: dai,
      wbtc: wbtc,
      weth: weth,
      deployer: tokenOwner,
      timestamp: block.timestamp
    });

    _saveTokenReport(report);

    console.log('\nToken addresses saved to ./reports/tokens-report.json');
  }

  function _saveTokenReport(TokenReport memory report) internal {
    IMetadataReporter metadataReporter = IMetadataReporter(
      _deployFromArtifacts('MetadataReporter.sol:MetadataReporter')
    );

    string memory output = 'tokens';
    output.serialize('weth', report.weth);
    output.serialize('usdc', report.usdc);
    output.serialize('usdt', report.usdt);
    output.serialize('dai', report.dai);
    output.serialize('wbtc', report.wbtc);
    output.serialize('deployer', report.deployer);
    output.serialize('timestamp', report.timestamp);

    string memory timestamp = vm.toString(block.timestamp);
    vm.writeJson(output, string.concat('./reports/', timestamp, '-tokens-deployment.json'));
    // Also save as latest
    vm.writeJson(output, './reports/tokens-report.json');
  }
}
