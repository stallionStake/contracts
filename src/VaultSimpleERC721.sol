// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.18;

import {Ownable, Context} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {VaultBase} from "./evc/VaultBase.sol";
import {IEVC} from "./evc/IEthereumVaultConnector.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {EVCUtil} from "./evc/EVCUtil.sol";
import {EVCClient} from "./evc/EVCClient.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title VaultSimple
/// @dev It provides basic functionality for vaults.
/// @notice In this contract, the EVC is authenticated before any action that may affect the state of the vault or an
/// account. This is done to ensure that if it's EVC calling, the account is correctly authorized. This contract does
/// not take the supply cap into account when calculating max deposit and max mint values.
contract VaultSimpleERC721 is VaultBase, Ownable, ERC721 {
    event SupplyCapSet(uint256 newSupplyCap);

    error SnapshotNotTaken();
    error SupplyCapExceeded();

    uint256 internal _totalAssets;
    uint256 public supplyCap;

    IERC721 public asset;

    constructor(
        IEVC _evc,
        IERC721 _asset,
        string memory name,
        string memory symbol

    ) VaultBase(_evc) Ownable() ERC721(name, symbol) {
        asset = _asset;
    }

    /// @notice Retrieves the message sender in the context of the EVC.
    /// @dev This function returns the account on behalf of which the current operation is being performed, which is
    /// either msg.sender or the account authenticated by the EVC.
    /// @return The address of the message sender.
    function _msgSender() internal view override (EVCUtil, Context) returns (address) {
        return EVCUtil._msgSender();
    }

    /// @notice Sets the supply cap of the vault.
    /// @param newSupplyCap The new supply cap.
    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
        emit SupplyCapSet(newSupplyCap);
    }

    /// @notice Creates a snapshot of the vault.
    /// @dev This function is called before any action that may affect the vault's state.
    /// @return A snapshot of the vault's state.
    function doCreateVaultSnapshot() internal virtual override returns (bytes memory) {
        // make total assets snapshot here and return it:
        return abi.encode(_totalAssets);
    }

    function totalSupply() public view returns(uint256) {
        return _totalAssets;
    }

    /// @notice Checks the vault's status.
    /// @dev This function is called after any action that may affect the vault's state.
    /// @param oldSnapshot The snapshot of the vault's state before the action.
    function doCheckVaultStatus(bytes memory oldSnapshot) internal virtual override {
        // sanity check in case the snapshot hasn't been taken
        if (oldSnapshot.length == 0) revert SnapshotNotTaken();

        // validate the vault state here:
        uint256 initialSupply = abi.decode(oldSnapshot, (uint256));
        uint256 finalSupply = totalSupply();

        // the supply cap can be implemented like this:
        if (supplyCap != 0 && finalSupply > supplyCap && finalSupply > initialSupply) {
            revert SupplyCapExceeded();
        }
    }

    /// @notice Checks the status of an account.
    /// @dev This function is called after any action that may affect the account's state.
    function doCheckAccountStatus(address, address[] calldata) internal view virtual override {
        // no need to do anything here because the vault does not allow borrowing
    }

    /// @notice Disables the controller.
    /// @dev The controller is only disabled if the account has no debt.
    function disableController() external virtual override nonReentrant {
        // this vault doesn't allow borrowing, so we can't check that the account has no debt.
        // this vault should never be a controller, but user errors can happen
        EVCClient.disableController(_msgSender());
    }

    /// @notice Returns the total assets of the vault.
    /// @return The total assets.
    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// @notice Converts assets to shares.
    /// @dev That function is manipulable in its current form as it uses exact values. Considering that other vaults may
    /// rely on it, for a production vault, a manipulation resistant mechanism should be implemented.
    /// @dev Considering that this function may be relied on by controller vaults, it's read-only re-entrancy protected.
    /// @return The converted shares.
    function convertToShares(uint256 _id) public view virtual nonReentrantRO returns (uint256) {

        return _id;
    }

    /// @notice Converts shares to assets.
    /// @dev That function is manipulable in its current form as it uses exact values. Considering that other vaults may
    /// rely on it, for a production vault, a manipulation resistant mechanism should be implemented.
    /// @dev Considering that this function may be relied on by controller vaults, it's read-only re-entrancy protected.
    /// @return The converted assets.
    function convertToAssets(uint256 _id) public view virtual nonReentrantRO returns (uint256) {

        return _id;
    }

    /// @notice Transfers a certain amount of shares to a recipient.
    /// @param to The recipient of the transfer.
    function transfer(
        address to,
        uint256 tokenId
    ) public callThroughEVC nonReentrant returns (bool) {
        createVaultSnapshot();
        
        require(ownerOf(tokenId) == _msgSender(), "ERC721: transfer of token that is not own");
        _transfer(msg.sender, to, tokenId);

        // despite the fact that the vault status check might not be needed for shares transfer with current logic, it's
        // added here so that if anyone changes the snapshot/vault status check mechanisms in the inheriting contracts,
        // they will not forget to add the vault status check here
        requireAccountAndVaultStatusCheck(_msgSender());
        return true;
    }

    /// @notice Transfers a certain amount of shares from a sender to a recipient.
    /// @param from The sender of the transfer.
    /// @param to The recipient of the transfer.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override callThroughEVC nonReentrant {
        createVaultSnapshot();
        
        super.transferFrom(from, to, tokenId);

        // despite the fact that the vault status check might not be needed for shares transfer with current logic, it's
        // added here so that if anyone changes the snapshot/vault status check mechanisms in the inheriting contracts,
        // they will not forget to add the vault status check here
        requireAccountAndVaultStatusCheck(from);
    }

    /// @notice Deposits a certain amount of assets for a receiver.
    /// @param receiver The receiver of the deposit.
    /// @return shares The shares equivalent to the deposited assets.
    function deposit(
        uint256 tokenId,
        address receiver
    ) public virtual callThroughEVC nonReentrant returns (uint256 shares) {
        createVaultSnapshot();

        asset.transferFrom(_msgSender(), address(this), tokenId);
        _mint(receiver, tokenId);

        _totalAssets += 1;
        requireVaultStatusCheck();
    }

    /// @notice Mints a certain amount of shares for a receiver.
    /// @param receiver The receiver of the mint.
    function mint(
        uint256 tokenId,
        address receiver
    ) public virtual callThroughEVC nonReentrant returns (uint256 assets) {
        createVaultSnapshot();
        asset.transferFrom(_msgSender(), address(this), tokenId);
        _mint(receiver, tokenId);

        _totalAssets += 1;
        requireVaultStatusCheck();
    }

    /// @notice Withdraws a certain amount of assets for a receiver.
    /// @param receiver The receiver of the withdrawal.
    /// @param owner The owner of the assets.
    function withdraw(
        uint256 tokenId,
        address receiver,
        address owner
    ) public virtual  callThroughEVC nonReentrant returns (uint256 shares) {
        createVaultSnapshot();
        require(ownerOf(tokenId) == owner, "Not the owner");

        asset.transferFrom(address(this), receiver, tokenId);
        _burn(tokenId);
        _totalAssets -= 1;
        requireAccountAndVaultStatusCheck(owner);
    }

    /// @notice Redeems a certain amount of shares for a receiver.
    /// @param receiver The receiver of the redemption.
    /// @param owner The owner of the shares.
    function redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) public virtual callThroughEVC nonReentrant returns (uint256 assets) {
        createVaultSnapshot();
        require(ownerOf(tokenId) == owner, "Not the owner");

        asset.transferFrom(address(this), receiver, tokenId);
        _burn(tokenId);
        _totalAssets -= 1;
        
        requireAccountAndVaultStatusCheck(owner);
    }
}
