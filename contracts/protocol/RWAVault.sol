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
/// @notice RWA Vault is tokenized vault built using ERC-4626 standard
contract RWAVault is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ERC4626Upgradeable
{
    bytes32 public constant ROLE_ORACLE_MANAGER = keccak256("ROLE_ORACLE_MANAGER");
    bytes32 public constant ROLE_GRANT_MANAGER = keccak256("ROLE_GRANT_MANAGER");
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
    event GrantManagerAdded(address _account);
    event GrantManagerRemoved(address _account);
    event AdminTransferred(address _oldOwner, address _newOwner);
    event PoolStatusUpdated(address indexed _by, PoolStatus _prevStatus, PoolStatus _newStatus);
    event AssetUnderManagementUpdated(address indexed _by, uint256 _prevValue, uint256 _newValue);
    event Granted(address indexed _by, address _to, uint256 _amount);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _poolManager address of pool manager
    /// @param _poolToken address of the underlying token used for the vault for accounting
    /// @param _treasury address of treasury that is responsible for deploying pool tokens into RWAs
    /// @param _oracleManager address of oracle manager that is responsible 
    ///                       for update real time value of underlying RWAs
    /// @param _poolSize maximum amount pool can manage
    function initialize(
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
        __ERC20_init("RWA Vault", "RWAV");

        _grantRole(DEFAULT_ADMIN_ROLE, _poolManager);
        _grantRole(ROLE_ORACLE_MANAGER, _oracleManager);
        poolToken = _poolToken;
        treasury = _treasury;
        poolSize = _poolSize;
        nonReservePercentage = 7500;
    }

    /// @notice returns the total amount of underlying assets held by the vault
    function totalAssets() public view virtual override returns (uint256) {
        return  IERC20Upgradeable(poolToken).balanceOf(address(this)) +
                IERC20Upgradeable(poolToken).balanceOf(treasury) +
                assetUnderManagement;
    }

    /// @notice returns the maximum amount of underlying assets that can be deposited
    function maxDeposit(address) public view virtual override returns (uint256) {
        return poolSize - totalAssets();
    }

    /// @notice returns the maximum amount of shares that can be minted
    function maxMint(address) public view virtual override returns (uint256) {
        return previewDeposit(poolSize - totalAssets());
    }

    /// @notice  returns the maximum amount of underlying assets that can be withdrawn
    function maxWithdraw(address) public view virtual override returns (uint256) {
        return IERC20Upgradeable(poolToken).balanceOf(address(this));
    }

    /// @notice returns the maximum amount of shares that can be redeemed
    function maxRedeem(address) public view virtual override returns (uint256) {
        return _convertToShares(maxWithdraw(address(0)), MathUpgradeable.Rounding.Down);
    }

    /// @notice returns real time supplied APY of the vault 
    function suppliedAPY() public view returns (int256 APY) {
        int256 _amount = int256(10 ** decimals());
        int256 amount = int256(convertToAssets(uint256(_amount)));
        int256 durationInDays = int256((block.timestamp - activationTime) / 1 days);
        APY = ((amount - _amount) * 1e4 * 365) / (_amount * durationInDays);
    }

    /// @notice returns true if given address has oracle manager role
    /// @param _account address to query for role
    function isOracleManager(address _account) public view returns (bool) {
        return hasRole(ROLE_ORACLE_MANAGER, _account);
    }

    /// @notice returns true if given address has grant manager role
    /// @param _account address to query for role
    function isGrantManager(address _account) public view returns (bool) {
        return hasRole(ROLE_GRANT_MANAGER, _account);
    }

    /// @notice deposits assets of underlying tokens into the vault and grants ownership of shares to receiver
    /// @param assets amount of pool token to be deposited into vault 
    /// @param receiver address of receiver
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        shares = super.deposit(assets, receiver);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), treasury, (assets * nonReservePercentage) / 10000);
    }

    /// @notice mints exactly shares vault shares to receiver by depositing assets of underlying tokens
    /// @param shares amount of rwa vault shares to be minted from vault 
    /// @param receiver address of receiver
    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        assets = super.mint(shares, receiver);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), treasury, (assets * nonReservePercentage) / 10000);
    }

    /// @notice burns shares from owner and send exactly assets token from the vault to receiver
    /// @param assets amount of pool token to be withdrawn from vault 
    /// @param receiver address of receiver
    /// @param owner address of owner
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        return super.withdraw(assets, receiver, owner);
    }

    /// @notice redeems a specific number of shares from owner and sends assets of underlying token from the vault to receiver
    /// @param shares amount of shares to be redeemed from vault 
    /// @param receiver address of receiver
    /// @param owner address of owner
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        return super.redeem(shares, receiver, owner);
    }

    /// @notice updates asset under management i.e. total value of underlying RWAs in terms of pool token
    /// @dev oracle should calculate AUM on regular interval and record on-chain
    /// @param _assetUnderManagement total value of underlying RWAs in terms of pool token 
    function updateAssetUnderManagement(uint256 _assetUnderManagement) external onlyRole(ROLE_ORACLE_MANAGER) {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        emit AssetUnderManagementUpdated(_msgSender(), assetUnderManagement, _assetUnderManagement);
        assetUnderManagement = _assetUnderManagement;
    }
    
    /// @notice grants tokens to borrower
    /// @param _to address of borrower
    /// @param _amount amount of pool tokens to grant as a loan
    function grant(address _to, uint256 _amount) external onlyRole(ROLE_GRANT_MANAGER) {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), _to, _amount);
        emit Granted(_msgSender(), _to, _amount);
    }

    /// @notice Updates pool size
    /// @param _poolSize new value to update
    function updatePoolSize(uint256 _poolSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(_poolSize < totalAssets()) revert InvalidPoolSize(_poolSize);
        poolSize = _poolSize;
    }

    /// @notice activates the pool for deposit, withdraw
    function activatePool() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(status != PoolStatus.PENDING) revert InvalidStatusUpdate();
        status = PoolStatus.ACTIVE;
        activationTime = uint64(block.timestamp);
        emit PoolStatusUpdated(_msgSender(), PoolStatus.PENDING, PoolStatus.ACTIVE);
    }

    /// @notice closes the pool after full settlement
    function closePool() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(status == PoolStatus.CLOSE) revert InvalidStatusUpdate();
        if(totalAssets() != 0 && totalSupply() != 0)  revert WithdrawalPending();
        emit PoolStatusUpdated(_msgSender(), status, PoolStatus.CLOSE);
        status = PoolStatus.CLOSE;
    }

    /// @notice updates percentage of amount that deducted from each depoist and sent to treasury
    /// @param _percentage new percentage in 2 basis point (ex: for 10.30% => 1003) 
    function updateNonReservePercentage(uint64 _percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nonReservePercentage = _percentage;
    }

    /// @notice pauses the contract
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice unpauses the contract
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice adds new oracle manager
    function addOracleManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ROLE_ORACLE_MANAGER, _account);
        emit OracleManagerAdded(_account);
    }

    /// @notice removes existing oracle manager
    function removeOracleManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ROLE_ORACLE_MANAGER, _account);
        emit OracleManagerRemoved(_account);
    }

    /// @notice adds new grant manager
    function addGrantManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ROLE_GRANT_MANAGER, _account);
        emit GrantManagerAdded(_account);
    }

    /// @notice removes existing grant manager
    function removeGrantManager(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ROLE_GRANT_MANAGER, _account);
        emit GrantManagerRemoved(_account);
    }

    /// @notice transfer admin role to new account
    function transferAdmin(address _newOwner) public {
        grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AdminTransferred(_msgSender(), _newOwner);
    }    

    /// @notice grants a role to account
    function grantRole(bytes32 role, address _account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
        whenNotPaused
    {
        _grantRole(role, _account);
    }

    // revokes a role
    function revokeRole(bytes32 role, address _account)
        public
        override
        onlyRole(getRoleAdmin(role))        
        whenNotPaused
    {
        _revokeRole(role, _account);
    }

    /// @notice hook called at time of transfer
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

    // @notice internal function to check authorized upgrades
    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}