// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

error PoolIsNotActive();
error InvalidPoolSize(uint256 _poolSize);
error InvalidStatusUpdate();
error WithdrawalPending();

/// @title RWA Vault
contract RWAVault is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ERC4626Upgradeable
{
    bytes32 public constant ROLE_ORACLE_MANAGER = keccak256("ROLE_ORACLE_MANAGER");
    address public poolToken;
    address public treasury;
    PoolStatus public status;
    uint256 public poolSize;
    uint256 public assetUnderManagement;
    uint64 public activationTime;
    uint64 public nonReservePercentage;
    
    enum PoolStatus {PENDING, ACTIVE, CLOSE}
    
    event OracleManagerAdded(address _account);
    event OracleManagerRemoved(address _account);
    event AdminTransferred(address _oldOwner, address _newOwner);
    event PoolStatusUpdated(address indexed _by, PoolStatus _prevStatus, PoolStatus _newStatus);
    event AssetUnderManagementUpdated(address indexed _by, uint256 _prevValue, uint256 _newValue);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _poolName,
        string calldata _poolSymbol,
        address _poolManager,
        address _poolToken,
        address _treasury,
        address _oracleManager,
        uint256 _poolSize
    )
        public
        initializer
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ERC4626_init(IERC20Upgradeable(_poolToken));
        __ERC20_init(_poolName, _poolSymbol);

        _grantRole(DEFAULT_ADMIN_ROLE, _poolManager);
        _grantRole(ROLE_ORACLE_MANAGER, _oracleManager);
        poolToken = _poolToken;
        treasury = _treasury;
        poolSize = _poolSize;
        nonReservePercentage = 9000;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return  IERC20Upgradeable(poolToken).balanceOf(address(this)) +
                IERC20Upgradeable(poolToken).balanceOf(address(this)) + 
                assetUnderManagement;
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return poolSize - assetUnderManagement;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return previewDeposit(poolSize - assetUnderManagement);
    }

    function maxWithdraw(address) public view virtual override returns (uint256) {
        return IERC20Upgradeable(poolToken).balanceOf(address(this));
    }

    function maxRedeem(address) public view virtual override returns (uint256) {
        return _convertToShares(maxWithdraw(address(0)), MathUpgradeable.Rounding.Down);
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        shares = super.deposit(assets, receiver);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), treasury, (assets * nonReservePercentage) / 10000);
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        assets = super.mint(shares, receiver);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), treasury, (assets * nonReservePercentage) / 10000);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        return super.redeem(shares, receiver, owner);
    }

    function updatePoolSize(uint256 _poolSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(_poolSize < assetUnderManagement) revert InvalidPoolSize(_poolSize);
        poolSize = _poolSize;
    }

    function activatePool() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(status != PoolStatus.PENDING) revert InvalidStatusUpdate();
        status = PoolStatus.ACTIVE;
        activationTime = uint64(block.timestamp);
        emit PoolStatusUpdated(_msgSender(), PoolStatus.PENDING, PoolStatus.ACTIVE);
    }

    function closePool() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(status == PoolStatus.CLOSE) revert InvalidStatusUpdate();
        if(totalAssets() != 0 && totalSupply() != 0)  revert WithdrawalPending();
        emit PoolStatusUpdated(_msgSender(), status, PoolStatus.CLOSE);
        status = PoolStatus.CLOSE;
    }

    function updateAssetUnderManagement(uint256 _assetUnderManagement) external onlyRole(ROLE_ORACLE_MANAGER) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        emit AssetUnderManagementUpdated(_msgSender(), assetUnderManagement, _assetUnderManagement);
        assetUnderManagement = _assetUnderManagement;
    }

    function updateNonReservePercentage(uint64 _percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nonReservePercentage = _percentage;
    }

    function isOracleManager(address _account) public view returns (bool) {
        return hasRole(ROLE_ORACLE_MANAGER, _account);
    }

    function suppliedAPY() public view returns (int256 APY) {
        int256 _amount = int256(10 ** decimals());
        int256 amount = int256(convertToAssets(uint256(_amount)));
        int256 durationInDays = int256((block.timestamp - activationTime) / 1 days);
        APY = ((amount - _amount) * 1e4 * 365) / (_amount * durationInDays);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addOracleManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ROLE_ORACLE_MANAGER, _account);
        emit OracleManagerAdded(_account);
    }

    function removeOracleManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ROLE_ORACLE_MANAGER, _account);
        emit OracleManagerRemoved(_account);
    }

    function transferAdmin(address _newOwner) public {
        grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AdminTransferred(_msgSender(), _newOwner);
    }    

    function grantRole(bytes32 role, address _account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
        whenNotPaused
    {
        _grantRole(role, _account);
    }

    function revokeRole(bytes32 role, address _account)
        public
        override
        onlyRole(getRoleAdmin(role))        
        whenNotPaused
    {
        _revokeRole(role, _account);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    )
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}