// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721/IERC165.sol";
import "../ERC721/String.sol";
import "../ERC721/Address.sol";

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";

contract ERC1155 is IERC165, IERC1155 IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;

    string public name;
    string public symbol;

    // 代币种类id - 账户account - 余额的 映射
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // 发起方地址 - 授权地址 - 是否授权
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId;
    }

    function balanceOf(address account, uint256 tokenId) public view returns (uint256) {
        require(account != address(0),"ERC1155: address zero is not a valid owner");
        return _balances[tokenId][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length,"ERC1155: accounts and ids length mismatch");
        uint256[] memory balanceOfBatch = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++ ) {
            balanceOfBatch[i] = balanceOf(accounts[i], ids[i]);
        }
        return balanceOfBatch;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        equire(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address amount,
        address operator
    ) public view virtual override {
        return _operatorApprovals[account][operator];
    }

    function safeBatchTransferFrom(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0),"ERC1155: transfer to the zero address");
        unchecked {
            _balances[id][to] += amount;
        }

        emit TransferSingle(operator, from, to, id, amount);
         _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data); 
    }

    function safeBatchTransferFrom(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // 调用者是持有者或是被授权
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        // 通过for循环更新持仓  
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        // 安全检查
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(
        address to,
        uint256 memory id,
        uint256 memory amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0),"ERC1155: mint to the zero address");
        address operator = msg.sender;

        _balances[id][to] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 memory tokenId,
        uint256 memory amount
    ) internal virtual {
        require(from != address(0),"ERC1155: burn from the zero address");
        address operator = msg.sender;
        uint256 fromBalance = _balances[tokenId][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");

        unchecked {
            _balances[tokenId] = fromBalance - amount;
        }
        emit TransferSingle(operator, from, address(0), tokenId, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 memory id,
        uint256 memory amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
           try IERC1155Receiver(to).onERC1155Received(
                operator, from, id, amount, data
                ) returns (bytes response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
           } catch Error(string memory reson) {
                revert(reson);
           } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
           }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }





}

