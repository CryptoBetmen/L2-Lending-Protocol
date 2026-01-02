// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockAggregator} from '../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';

/**
 * @title ChainlinkMockAggregator
 * @notice Mock Chainlink aggregator with settable price
 */
contract ChainlinkMockAggregator is MockAggregator {
  constructor(uint8 decimals_) MockAggregator(0) {
    // Initialize with zero, will be set later
  }

  function setLatestAnswer(int256 answer) external {
    _latestAnswer = answer;
    emit AnswerUpdated(answer, 0, block.timestamp);
  }
}
