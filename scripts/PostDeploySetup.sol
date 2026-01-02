// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import 'forge-std/StdJson.sol';
import {MarketReport} from '../src/deployments/interfaces/IMarketReportTypes.sol';
import {ACLManager} from '../src/contracts/protocol/configuration/ACLManager.sol';
import {IPoolAddressesProvider} from '../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {Ownable} from '../src/contracts/dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title PostDeploySetup
 * @notice Post-deployment setup script for Aave v3 fork
 * @dev This script performs additional setup after initial deployment:
 * - Configures RISK_ADMIN role (if needed)
 * - Transfers ownership to governance/multisig (optional)
 * - Validates role configuration
 *
 * Prerequisites:
 * - Market must be deployed (run DeployArbitrumSepoliaMarket first)
 * - Market report must exist at ./reports/market-report.json
 *
 * Usage:
 * forge script scripts/PostDeploySetup.sol:PostDeploySetup \
 *   --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --slow
 */
contract PostDeploySetup is Script {
  using stdJson for string;

  // Role IDs (from ACLManager)
  bytes32 public constant POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
  bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256('EMERGENCY_ADMIN');
  bytes32 public constant RISK_ADMIN_ROLE = keccak256('RISK_ADMIN');

  function run() external {
    console.log('=== Post-Deployment Setup ===');

    // Load market report
    string memory jsonReport = vm.readFile('./reports/market-report.json');
    MarketReport memory report;
    report.poolAddressesProvider = jsonReport.readAddress('.poolAddressesProvider');
    report.aclManager = jsonReport.readAddress('.aclManager');

    require(report.poolAddressesProvider != address(0), 'PoolAddressesProvider not found');
    require(report.aclManager != address(0), 'ACLManager not found');

    console.log('PoolAddressesProvider:', report.poolAddressesProvider);
    console.log('ACLManager:', report.aclManager);

    ACLManager aclManager = ACLManager(report.aclManager);
    IPoolAddressesProvider provider = IPoolAddressesProvider(report.poolAddressesProvider);

    // Get current deployer (msg.sender)
    address deployer = msg.sender;

    // Check if RISK_ADMIN should be set
    // For MVP: RISK_ADMIN can be the same as POOL_ADMIN (deployer)
    // For production: RISK_ADMIN should be a separate address (multisig/governance)
    address riskAdmin = vm.envOr('RISK_ADMIN_ADDRESS', deployer);

    // Optional: Transfer ownership to governance/multisig
    address governanceAddress = vm.envOr('GOVERNANCE_ADDRESS', address(0));

    vm.startBroadcast();

    // Setup RISK_ADMIN role (if not already set)
    if (!aclManager.hasRole(RISK_ADMIN_ROLE, riskAdmin)) {
      console.log('Setting RISK_ADMIN to:', riskAdmin);
      aclManager.addRiskAdmin(riskAdmin);
      console.log('RISK_ADMIN role granted');
    } else {
      console.log('RISK_ADMIN already set');
    }

    // Transfer ownership to governance (if provided)
    if (governanceAddress != address(0)) {
      console.log('Transferring ownership to governance:', governanceAddress);

      // Transfer PoolAddressesProvider ownership
      address currentOwner = Ownable(report.poolAddressesProvider).owner();
      if (currentOwner == deployer) {
        Ownable(report.poolAddressesProvider).transferOwnership(governanceAddress);
        console.log('PoolAddressesProvider ownership transferred');
      }

      // Transfer PoolAddressesProviderRegistry ownership (if exists)
      address registry = provider.getAddress('POOL_ADDRESSES_PROVIDER_REGISTRY');
      if (registry != address(0)) {
        address registryOwner = Ownable(registry).owner();
        if (registryOwner == deployer) {
          Ownable(registry).transferOwnership(governanceAddress);
          console.log('PoolAddressesProviderRegistry ownership transferred');
        }
      }
    }

    vm.stopBroadcast();

    // Validate roles
    console.log('\n=== Role Validation ===');
    console.log('POOL_ADMIN:', aclManager.isPoolAdmin(deployer) ? 'YES' : 'NO');
    console.log('EMERGENCY_ADMIN:', aclManager.isEmergencyAdmin(deployer) ? 'YES' : 'NO');
    console.log('RISK_ADMIN:', aclManager.isRiskAdmin(riskAdmin) ? 'YES' : 'NO');

    console.log('\n=== Post-Deployment Setup Complete ===');
  }
}
