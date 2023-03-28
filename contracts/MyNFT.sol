// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC721Receiver.sol';

contract MyNFT {

    // name of the NFT
    string public name;
    // symbol of the NFT
    string public symbol;

    // keep track of the tokenId to be minted
    uint public nextTokenIdToMint;
    // store the contract owner address 
    address public contractOwner;

    // keep track of the which tokenId belongs to which client address
    mapping(uint => address) internal _owners;
    // keep tract of how many tokenIds does a specific client have
    mapping(address => uint) internal _balances;

    // keep track of the tokenIds which have been approved by the owner 
    // to be transfered by spender on his/her behalf
    mapping(uint => address) internal _tokenApprovals;
    // keeps track of the spender who can transfer any of the owners(client/operator) nft
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    // keeps track of the tokenURI of a specific tokenId
    mapping(uint => string) _tokenUris;


    event Transfer(address indexed _from,address indexed _to,uint indexed _tokenId);
    event Approval(address indexed _owner,address indexed _approved,uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // when contract is deployed this constructor will only execute once;
    // name of the NFT will be set
    // symbol of the NFT will be set
    // contract owner will be set as msg.sender is the person's address who deploys the contract
    // first tokenId will become 0(zero)  
    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
        nextTokenIdToMint = 0;
    }


    // returns how many NFT does client have
    function balanceOf(address _owner) public view returns(uint){
        require(_owner!=address(0),"cannot return the balance of zero address");
        return _balances[_owner];
    }

    // returns the owner address of the nft
    function ownerOf(uint _tokenId) public view returns(address){
        require(_owners[_tokenId]!=address(0),"this nft does not yet minted");
        return _owners[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId,"");
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) public payable {
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "you are not owner nor approved to send nft");
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data),"ERC721Receiver not implemented");
    }

    // unsafe transfer without onERC721Received, used for contracts that don't implement onERC721Received function
    function transferFrom(address _from, address _to, uint _tokenId) public payable {
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender],"you are not owner nor approved to send nft");
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint _tokenId) public payable {
        require(ownerOf(_tokenId) == msg.sender,"you are not the owner of the nft");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint _tokenId) public view returns(address) {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner,address _operator) public view returns(bool){
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to,string memory _uri) public {
        require(msg.sender == contractOwner,"only owner can mint nft");
        _owners[nextTokenIdToMint] = _to;
        _balances[_to]++;
        _tokenUris[nextTokenIdToMint] = _uri;
        emit Transfer(address(0), _to, nextTokenIdToMint);
        nextTokenIdToMint++;
    } 

    function tokenURI(uint _tokenId) public view returns(string memory){
        return _tokenUris[_tokenId];
    }

    function totalSupply() public view returns(uint) {
        return nextTokenIdToMint;
    }
    // INTERNAL FUNCTIONS

    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) private returns(bool){
        // check if to(address) is an contract, if yes, to.code.length will always > 0
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval){
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if(reason.length == 0) {
                    revert("transfer to non ERC721Receiver implemented");
                } else {
                    // @solidity memroy-safe-assembly
                    assembly{
                        revert(add(32,reason),mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // unsafe transfer function
    function _transfer(address _from, address _to,uint _tokenId) internal {
        require(_owners[_tokenId] == _from,"you are not the owner of this nft");
        require(_to!=address(0),"cannot transfer nft to zero address");

        delete _tokenApprovals[_tokenId];
        _balances[_from]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}