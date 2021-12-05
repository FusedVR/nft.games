// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

// Child Chain Manager
// 0xb5505a6d998549090530911180f38aC5130101c6 - Mumbai
// 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa - Main Polygon

// Located at https://github.com/FusedVR/nft.games/blob/master/Contracts/PolygonMintable1555.sol

contract FusedVRCollection is ERC1155PresetMinterPauser{
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(address childChainManager) ERC1155PresetMinterPauser("https://raw.githubusercontent.com/FusedVR/nft.games/master/") {
        name = "FusedVR Render Streaming Collection";
        symbol = "FRS";
        _setupRole(DEPOSITOR_ROLE, childChainManager);
    }
    
    /**
     * @notice called when tokens are deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokens for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded ids array and amounts array
     */
    function deposit(address user, bytes calldata depositData)
        external
        virtual
    {
        require(hasRole(DEPOSITOR_ROLE, _msgSender()), "FusedVRCollection: must have depositor role to deposit");
        (
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(depositData, (uint256[], uint256[], bytes));

        require(
            user != address(0),
            "FusedVRCollection: INVALID_DEPOSIT_USER"
        );

        _mintBatch(user, ids, amounts, data);
    }

    /**
     * @notice called when user wants to withdraw single token back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param id id to withdraw
     * @param amount amount to withdraw
     */
    function withdrawSingle(uint256 id, uint256 amount) external {
        _burn(_msgSender(), id, amount);
    }

    /**
     * @notice called when user wants to batch withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param ids ids to withdraw
     * @param amounts amounts to withdraw
     */
    function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts)
        external
    {
        _burnBatch(_msgSender(), ids, amounts);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE_{id}` or the generic 'MINTER_ROLE'
     */
    function mint( address to, uint256 id, uint256 amount, bytes memory data ) 
    public override {
        bool roleCheck = hasRole(MINTER_ROLE, _msgSender()) || hasRole(_getMinterRoleID(id), _msgSender());
        require(roleCheck, "FusedVRCollection: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     * Requirements:
     *
     * - the caller must have the the generic 'MINTER_ROLE' and this will not work even if sender has correct IDs
     */
    function mintBatch( address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) 
    public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "FusedVRCollection: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string( abi.encodePacked( super.uri(id), Strings.toString(id), "/meta.json" ));
    }

    /**
     * @dev Grants minter `role` based on ID to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantMintIDRole(uint256 id, address account) public virtual {
         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FusedVRCollection: must have admin role to grant minter status");
        _grantRole(_getMinterRoleID(id), account);
    }

    /**
     * @dev Gets the Hash Representation the Minter Role for the given token ID
     *
     * Internal function without access restriction.
     */
    function _getMinterRoleID(uint256 id) internal virtual returns (bytes32) {
        return keccak256( abi.encodePacked( "MINTER_ROLE_", Strings.toString(id) ) );
    }

}
