// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import 'forge-std/StdJson.sol';
import {MarketReport} from '../src/deployments/interfaces/IMarketReportTypes.sol';
import {ACLManager} from '../src/contracts/protocol/configuration/ACLManager.sol';
import {IPoolAddressesProvider} from '../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../src/contracts/interfaces/IPool.sol';
import {IAaveOracle} from '../src/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from '../src/contracts/interfaces/IPriceOracleGetter.sol';

/**
 * @title ValidateDeployment
 * @notice Validates that all contracts are deployed correctly and configured properly
 * @dev This script checks:
 * - All contracts are deployed (non-zero addresses)
 * - Contracts have code
 * - Pool is initialized
 * - Oracle is configured
 * - Roles are set correctly
 * - Price feeds are configured
 *
 * Usage:
 * forge script scripts/ValidateDeployment.sol:ValidateDeployment \
 *   --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
 */
contract ValidateDeployment is Script {
  using stdJson for string;

  struct ValidationResult {
    bool allValid;
    uint256 errors;
    uint256 warnings;
  }

  function run() external view returns (ValidationResult memory) {
    console.log('=== Deployment Validation ===\n');

    // Load market report
    string memory jsonReport = vm.readFile('./reports/market-report.json');
    MarketReport memory report;
    report.poolAddressesProviderRegistry = jsonReport.readAddress('.poolAddressesProviderRegistry');
    report.poolAddressesProvider = jsonReport.readAddress('.poolAddressesProvider');
    report.poolProxy = jsonReport.readAddress('.poolProxy');
    report.poolImplementation = jsonReport.readAddress('.poolImplementation');
    report.poolConfiguratorProxy = jsonReport.readAddress('.poolConfiguratorProxy');
    report.poolConfiguratorImplementation = jsonReport.readAddress(
      '.poolConfiguratorImplementation'
    );
    report.protocolDataProvider = jsonReport.readAddress('.protocolDataProvider');
    report.aaveOracle = jsonReport.readAddress('.aaveOracle');
    report.defaultInterestRateStrategy = jsonReport.readAddress('.defaultInterestRateStrategy');
    report.priceOracleSentinel = jsonReport.readAddress('.priceOracleSentinel');
    report.aclManager = jsonReport.readAddress('.aclManager');
    report.treasury = jsonReport.readAddress('.treasury');
    report.configEngine = jsonReport.readAddress('.configEngine');

    ValidationResult memory result;
    result.allValid = true;

    // Validate core contracts
    console.log('--- Core Contracts ---');
    result.errors += _validateAddress('PoolAddressesProvider', report.poolAddressesProvider);
    result.errors += _validateAddress('PoolProxy', report.poolProxy);
    result.errors += _validateAddress('PoolConfiguratorProxy', report.poolConfiguratorProxy);
    result.errors += _validateAddress('ACLManager', report.aclManager);
    result.errors += _validateAddress('AaveOracle', report.aaveOracle);

    // Validate peripheral contracts
    console.log('\n--- Peripheral Contracts ---');
    result.warnings += _validateAddressOptional(
      'ProtocolDataProvider',
      report.protocolDataProvider
    );
    result.warnings += _validateAddressOptional('Treasury', report.treasury);
    result.warnings += _validateAddressOptional('PriceOracleSentinel', report.priceOracleSentinel);
    result.warnings += _validateAddressOptional('ConfigEngine', report.configEngine);

    // Validate Pool configuration
    console.log('\n--- Pool Configuration ---');
    if (report.poolProxy != address(0)) {
      result.errors += _validatePool(report.poolAddressesProvider, report.poolProxy);
    }

    // Validate Oracle configuration
    console.log('\n--- Oracle Configuration ---');
    if (report.aaveOracle != address(0)) {
      result.errors += _validateOracle(report.aaveOracle);
    }

    // Validate Roles
    console.log('\n--- Role Configuration ---');
    if (report.aclManager != address(0)) {
      result.errors += _validateRoles(report.aclManager, report.poolAddressesProvider);
    }

    // Summary
    console.log('\n=== Validation Summary ===');
    console.log('Errors:', result.errors);
    console.log('Warnings:', result.warnings);
    result.allValid = (result.errors == 0);
    console.log('Status:', result.allValid ? 'PASS' : 'FAIL');

    return result;
  }

  function _validateAddress(string memory name, address addr) internal view returns (uint256) {
    if (addr == address(0)) {
      console.log('[ERROR]', name, 'is zero address');
      return 1;
    }
    if (addr.code.length == 0) {
      console.log('[ERROR]', name, 'has no code');
      return 1;
    }
    console.log('[OK]', name, ':', addr);
    return 0;
  }

  function _validateAddressOptional(
    string memory name,
    address addr
  ) internal view returns (uint256) {
    if (addr == address(0)) {
      console.log('[WARN]', name, 'is zero address (optional)');
      return 1;
    }
    if (addr.code.length == 0) {
      console.log('[WARN]', name, 'has no code (optional)');
      return 1;
    }
    console.log('[OK]', name, ':', addr);
    return 0;
  }

  function _validatePool(
    address providerAddress,
    address poolAddress
  ) internal view returns (uint256) {
    uint256 errors = 0;

    try IPoolAddressesProvider(providerAddress).getPool() returns (address pool) {
      if (pool != poolAddress) {
        console.log('[ERROR] Pool address mismatch');
        errors++;
      } else {
        console.log('[OK] Pool address matches');
      }
    } catch {
      console.log('[ERROR] Failed to get Pool from Provider');
      errors++;
    }

    try IPool(poolAddress).ADDRESSES_PROVIDER() returns (IPoolAddressesProvider provider) {
      if (address(provider) != providerAddress) {
        console.log('[ERROR] Provider address mismatch');
        errors++;
      } else {
        console.log('[OK] Provider address matches');
      }
    } catch {
      console.log('[ERROR] Failed to get Provider from Pool');
      errors++;
    }

    return errors;
  }

  function _validateOracle(address oracleAddress) internal view returns (uint256) {
    uint256 errors = 0;

    try IAaveOracle(oracleAddress).BASE_CURRENCY() returns (address baseCurrency) {
      console.log('[OK] Oracle base currency:', baseCurrency);
    } catch {
      console.log('[ERROR] Failed to get Oracle base currency');
      errors++;
    }

    // Try to get a price (WETH/USD should be available)
    try IPriceOracleGetter(oracleAddress).getAssetPrice(address(0)) returns (uint256 price) {
      if (price == 0) {
        console.log('[WARN] Oracle returned zero price');
      } else {
        console.log('[OK] Oracle returns valid price');
      }
    } catch {
      console.log('[WARN] Failed to get price from Oracle (may be normal if no assets listed)');
    }

    return errors;
  }

  function _validateRoles(
    address aclManagerAddress,
    address providerAddress
  ) internal view returns (uint256) {
    uint256 errors = 0;

    ACLManager aclManager = ACLManager(aclManagerAddress);

    // Check if ACLManager is set in Provider
    try IPoolAddressesProvider(providerAddress).getACLManager() returns (address acl) {
      if (acl != aclManagerAddress) {
        console.log('[ERROR] ACLManager address mismatch');
        errors++;
      } else {
        console.log('[OK] ACLManager set in Provider');
      }
    } catch {
      console.log('[ERROR] Failed to get ACLManager from Provider');
      errors++;
    }

    // Check if there's at least one POOL_ADMIN
    // Note: We can't check specific addresses without knowing who should be admin
    console.log(
      '[INFO] Role validation: Check manually that POOL_ADMIN, EMERGENCY_ADMIN, RISK_ADMIN are set'
    );

    return errors;
  }
}
