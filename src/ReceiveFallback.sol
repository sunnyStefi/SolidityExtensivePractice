// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract Receive {
    uint256 public number;
    // event Event(uint256 indexed number, string indexed text);

    receive() external payable {
        number = 1;
        // emit Event(number, "Test event");
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}

contract FallbackNotPayable {
    uint256 public number;

    fallback() external {
        number = 2;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}

contract FallbackNotPayableParams {
    uint256 public number;

    //123456 is 0x1e240
    fallback(bytes calldata input) external returns (bytes memory output) {
        require(input.length == 32, "Invalid data length for uint256");
        number = abi.decode(input, (uint256));
        return abi.encode(number);
    }
}

contract FallbackPayable {
    uint256 public number;

    fallback() external payable {
        number = 3;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}

contract ReceiveNotPayableFallback {
    uint256 public number;

    receive() external payable {
        number = 4;
    }

    fallback() external {
        number = 5;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}

contract ReceivePayableFallback {
    uint256 public number;

    receive() external payable {
        number = 6;
    }

    fallback() external payable {
        number = 7;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}
