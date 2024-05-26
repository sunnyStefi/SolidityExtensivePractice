// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import "../src/ReceiveFallback.sol";

/*
 * Combinations of 6 receive and fallback cases:
 * 1. receive
 * 2. not-payable fallback
 * 3. payable fallback (with params)
 * 4. receive + not-payable fallback
 * 5. receive + payable fallback
 * 
 * Scenarios:
 * 1. call with no ETH, no data
 * 2. call with ETH, no data
 * 3. call with no ETH, data
 * 4. send
 */
contract ReceiveFallbackTest is Test {
    address ALICE = makeAddr("ALICE");
    uint256 public number;
    uint256 constant AMOUNT = 0.1 ether;
    Receive public receiveContract;
    FallbackNotPayable public fallbackNotPayable;
    FallbackNotPayableParams public fallbackNotPayableParams;
    FallbackPayable public fallbackPayable;
    ReceiveNotPayableFallback public receiveNotPayableFallback;
    ReceivePayableFallback public receivePayableFallback;

    function setUp() public {
        vm.deal(ALICE, 1 ether);
        number = 0;
        receiveContract = new Receive();
        fallbackNotPayable = new FallbackNotPayable();
        fallbackNotPayableParams = new FallbackNotPayableParams();
        fallbackPayable = new FallbackPayable();
        receiveNotPayableFallback = new ReceiveNotPayableFallback();
        receivePayableFallback = new ReceivePayableFallback();
    }

    function test_Receive() public {
        vm.startPrank(ALICE);
        //CALL
        (bool success,) = address(receiveContract).call(abi.encodeWithSignature("nonExistingFunction()"));
        assert(receiveContract.number() == 0);
        (success,) = address(receiveContract).call{value: AMOUNT}("");
        assert(receiveContract.number() == 1);
        vm.expectRevert();
        (success,) = address(receiveContract).call{value: AMOUNT}(abi.encodeWithSignature("nonExistingFunction()"));

        //SEND
        // limited to 2300 gas & does not automatically revert the transaction if the transfer fails
        uint256 gasBefore = gasleft();
        success = payable(address(receiveContract)).send(AMOUNT); //Out of Gas: 9292! (empty is 231, log 234)
        uint256 gasAfter = gasleft();
        assertTrue(!success);
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);
        vm.stopPrank();
    }

    function test_NotPayableFallback() public {
        vm.startPrank(ALICE);
        //CALL
        (bool success,) = address(fallbackNotPayable).call(abi.encodeWithSignature("nonExistingFunction()"));
        assert(fallbackNotPayable.number() == 2);
        vm.expectRevert();
        (success,) = address(fallbackNotPayable).call{value: AMOUNT}("");
        vm.expectRevert();
        (success,) = address(fallbackNotPayable).call{value: AMOUNT}(abi.encodeWithSignature("nonExistingFunction()"));

        //SEND
        // limited to 2300 gas & does not automatically revert the transaction if the transfer fails
        uint256 gasBefore = gasleft();
        success = payable(address(fallbackNotPayable)).send(AMOUNT); //Out of Gas: 11549! (empty is 209)
        uint256 gasAfter = gasleft();
        assertTrue(!success);
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);
        vm.stopPrank();
    }

    function test_NotPayableFallbackParams() public {
        vm.startPrank(ALICE);
        //CALL
        bytes memory inputParam = abi.encode(uint256(123));
        (bool success,) = address(fallbackNotPayableParams).call(inputParam);
        assert(fallbackNotPayableParams.number() == 123);
        //same as above
        vm.stopPrank();
    }

    function test_PayableFallback() public {
        vm.startPrank(ALICE);
        //CALL
        (bool success,) = address(fallbackPayable).call(abi.encodeWithSignature("nonExistingFunction()"));
        assert(fallbackPayable.number() == 3);
        (success,) = address(fallbackPayable).call{value: AMOUNT}(""); //Gas used 7181
        assert(fallbackPayable.number() == 3);
        (success,) = address(fallbackPayable).call{value: AMOUNT}(abi.encodeWithSignature("nonExistingFunction()"));
        assert(fallbackPayable.number() == 3);
        //SEND
        // limited to 2300 gas & does not automatically revert the transaction if the transfer fails
        uint256 gasBefore = gasleft();
        success = payable(address(fallbackPayable)).send(AMOUNT); //Out of Gas: 9292
        uint256 gasAfter = gasleft();
        assertTrue(!success);
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);
        vm.stopPrank();
    }

    function test_ReceiveNotPayableFallback() public {
        vm.startPrank(ALICE);
        //CALL
        (bool success,) = address(receiveNotPayableFallback).call(abi.encodeWithSignature("nonExistingFunction()"));
        assert(receiveNotPayableFallback.number() == 5);
        (success,) = address(receiveNotPayableFallback).call{value: AMOUNT}("");
        assert(receiveNotPayableFallback.number() == 4);

        // the fallback cannot receive ETH: it's not called but it will not revert
        (success,) =
            address(receiveNotPayableFallback).call{value: AMOUNT}(abi.encodeWithSignature("nonExistingFunction()"));
        assert(receiveNotPayableFallback.number() == 4);
        //SEND
        // limited to 2300 gas & does not automatically revert the transaction if the transfer fails
        uint256 gasBefore = gasleft();
        success = payable(address(receiveNotPayableFallback)).send(AMOUNT); //Out of Gas: 9292!
        uint256 gasAfter = gasleft();
        assertTrue(!success);
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);
        vm.stopPrank();
    }

    function test_ReceivePayableFallback() public {
        vm.startPrank(ALICE);
        //CALL
        (bool success,) = address(receivePayableFallback).call(abi.encodeWithSignature("nonExistingFunction()"));
        assert(receivePayableFallback.number() == 7);
        (success,) = address(receivePayableFallback).call{value: AMOUNT}("");
        assert(receivePayableFallback.number() == 6);

        // fallback can receive ETH
        (success,) =
            address(receivePayableFallback).call{value: AMOUNT}(abi.encodeWithSignature("nonExistingFunction()"));
        assert(receivePayableFallback.number() == 7);
        //SEND
        // limited to 2300 gas & does not automatically revert the transaction if the transfer fails
        uint256 gasBefore = gasleft();
        success = payable(address(receivePayableFallback)).send(AMOUNT); //Out of Gas: 9292!
        uint256 gasAfter = gasleft();
        assertTrue(!success);
        uint256 gasUsed = gasBefore - gasAfter;
        console.log(gasUsed);
        vm.stopPrank();
    }
}
