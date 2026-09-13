// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC1363Receiver
/// @notice 接收 transferAndCall / transferFromAndCall 回调
interface IERC1363Receiver {
    function onTransferReceived(address operator, address from, uint value, bytes calldata data)
        external
        returns (bytes4);
}

/// @title IERC1363Spender
/// @notice 接收 approveAndCall 回调
interface IERC1363Spender {
    function onApprovalReceived(address owner, uint value, bytes calldata data) external returns (bytes4);
}

/// @title TokenErc1363
/// @notice 在 Token.sol 基础上实现 ERC-1363：转账/授权成功后回调合约
contract TokenErc1363 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name, string memory _symbol, uint _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function transferAndCall(address to, uint value) external returns (bool) {
        return transferAndCall(to, value, "");
    }

    function transferAndCall(address to, uint value, bytes memory data) public returns (bool) {
        _transfer(msg.sender, to, value);
        _checkOnTransferReceived(msg.sender, msg.sender, to, value, data);
        return true;
    }

    function transferFromAndCall(address from, address to, uint value) external returns (bool) {
        return transferFromAndCall(from, to, value, "");
    }

    function transferFromAndCall(address from, address to, uint value, bytes memory data) public returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        _checkOnTransferReceived(msg.sender, from, to, value, data);
        return true;
    }

    function approveAndCall(address spender, uint value) external returns (bool) {
        return approveAndCall(spender, value, "");
    }

    function approveAndCall(address spender, uint value, bytes memory data) public returns (bool) {
        _approve(msg.sender, spender, value);
        _checkOnApprovalReceived(msg.sender, spender, value, data);
        return true;
    }

    /// @notice ERC-165：ERC-1363 接口 ID 为 0xb0202a11
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC-165
            || interfaceId == 0x36372b07 // ERC-20
            || interfaceId == 0xb0202a11; // ERC-1363
    }

    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "TokenErc1363: transfer to zero address");
        require(balanceOf[from] >= value, "TokenErc1363: insufficient balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(spender != address(0), "TokenErc1363: approve to zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint value) internal {
        uint allowed = allowance[owner][spender];
        require(allowed >= value, "TokenErc1363: insufficient allowance");
        if (allowed != type(uint).max) {
            allowance[owner][spender] = allowed - value;
        }
    }

    function _checkOnTransferReceived(address operator, address from, address to, uint value, bytes memory data)
        internal
    {
        require(to.code.length > 0, "TokenErc1363: receiver not contract");
        bytes4 retval = IERC1363Receiver(to).onTransferReceived(operator, from, value, data);
        require(retval == IERC1363Receiver.onTransferReceived.selector, "TokenErc1363: invalid receiver");
    }

    function _checkOnApprovalReceived(address owner, address spender, uint value, bytes memory data) internal {
        require(spender.code.length > 0, "TokenErc1363: spender not contract");
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(owner, value, data);
        require(retval == IERC1363Spender.onApprovalReceived.selector, "TokenErc1363: invalid spender");
    }
}
