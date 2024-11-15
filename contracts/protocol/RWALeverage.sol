// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./RWAVault.sol";

error InvalidInputs(uint256 _amount, uint32 _lockingPeriodInSeconds);
error NotUnlocked(address _staker);
error AlreadyUnstaked(address _staker, uint256 _index);
error InvalidAmount(uint256 _amount);
error AlreadyBorrowed(address _staker, uint256 _amount);

/// @title RWA Leverage
contract RWALeverage is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    address public rwaToken;
    uint32 public slice;
    uint32 public maxStakeDurationAllowed;
    uint32 public minStakeDurationAllowed;
    uint128 public borrowAPY;
    uint128 public leverageAllowed;
    PoolStatus public status;
    mapping(address => StakeInfo[]) public stakes;
    mapping(address => LeverageInfo) public leverages;

    struct StakeInfo {
        uint256 amount;
        uint32 lockTime;
        uint32 unlockTime;
        bool isUnstaked;        
    }

    struct LeverageInfo {
        uint256 totalStaked;
        uint256 totalBorrowed;
        uint128 borrowAPY;
        uint32 borrowTime;
        uint32 paymentDue;
    }
    
    enum PoolStatus {PENDING, ACTIVE, CLOSE}

    event AdminTransferred(address _oldOwner, address _newOwner);
    event PoolStatusUpdated(PoolStatus _prevStatus, PoolStatus _newStatus);
    event Staked(address indexed _staker, uint256 _amount, uint256 _index);
    event Unstaked(address indexed _staker, uint256 _amount, uint256 _index);
    event SlicePeriodUpdated(uint32 _prevValue, uint256 _newValue);
    event MinMaxStakeDurationUpdated(uint32 _min, uint32 _max, uint32 _newMin, uint32 _newMax);
    event BorrowAPYUpdated(uint128 _prevAPY, uint128 _newAPY);
    event LeverageAllowedUpdated(uint128 _prevValue, uint128 _newValue);
    event Borrowed(address indexed _borrower, uint256 _amount, uint32 _paymentDue);

    modifier notZeroAddress(address _account) {
        require(_account != address(0), "address cannot be zero");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _rwaToken
    )
        public
        initializer
        notZeroAddress(_rwaToken)
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        rwaToken = _rwaToken;
        slice = 30 days;
        minStakeDurationAllowed = 30 days;
        maxStakeDurationAllowed = 360 days;
        borrowAPY = 1200;
        leverageAllowed = 7500;
    }

    function numberOfStakes(address _staker) external view returns(uint256) {
        return stakes[_staker].length;
    }

    function allStakes(address _staker) external view returns(StakeInfo[] memory) {
        return stakes[_staker];
    }

    function updatePoolStatus(PoolStatus _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit PoolStatusUpdated(status, _status);
        status = _status;
    }

    function updateSlicePeriod(uint32 _slice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SlicePeriodUpdated(slice, _slice);
        slice = _slice;
    }

    function updateMinMaxDurationAllowed(uint32 _min, uint32 _max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MinMaxStakeDurationUpdated(minStakeDurationAllowed, maxStakeDurationAllowed, _min, _max);
        minStakeDurationAllowed = _min;
        maxStakeDurationAllowed = _max;
    }

    function updateBorrowAPY(uint128 _borrowAPY) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit BorrowAPYUpdated(borrowAPY, _borrowAPY);
        borrowAPY = _borrowAPY;
    }

    function updateLeverageAllowed(uint128 _leverageAllowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit LeverageAllowedUpdated(leverageAllowed, _leverageAllowed);
        leverageAllowed = _leverageAllowed;
    }
    
    function stake(uint256 _amount, uint32 _lockingPeriodInSeconds) external {
        if(_amount == 0 || (_lockingPeriodInSeconds % slice != 0) || (_lockingPeriodInSeconds < minStakeDurationAllowed) || (_lockingPeriodInSeconds > maxStakeDurationAllowed)) {
            revert InvalidInputs(_amount, _lockingPeriodInSeconds);
        }
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(rwaToken), _msgSender(), address(this), _amount);
        uint32 _unlockTime = uint32(block.timestamp) + _lockingPeriodInSeconds;
        emit Staked(_msgSender(), _amount, stakes[_msgSender()].length);
        stakes[_msgSender()].push(StakeInfo(_amount, uint32(block.timestamp), _unlockTime, false));
        leverages[_msgSender()].totalStaked += _amount;
    }

    function unStake(uint256 _index) external {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        StakeInfo memory _stake = stakes[_msgSender()][_index];
        LeverageInfo memory _leverage = leverages[_msgSender()];
        if(_stake.isUnstaked) revert AlreadyUnstaked(_msgSender(), _index);
        if(block.timestamp < _stake.unlockTime) revert NotUnlocked(_msgSender());
        if(_stake.amount > (_leverage.totalStaked * leverageAllowed / 10000) - _leverage.totalBorrowed) revert InvalidAmount(_stake.amount);
        _stake.isUnstaked = true;
        _leverage.totalStaked -= _stake.amount;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(rwaToken), _msgSender(), _stake.amount);
        emit Unstaked(_msgSender(), _stake.amount, _index);
    }

    function borrow(uint256 _amount, uint32 _borrowPeriod) external {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        LeverageInfo memory _leverage = leverages[_msgSender()];
        if(_leverage.totalBorrowed != 0) revert AlreadyBorrowed(_msgSender(), _leverage.totalBorrowed);
        uint256 _userAssetValue = RWAVault(rwaToken).convertToAssets(_leverage.totalStaked);
        if(_amount > _userAssetValue * leverageAllowed / 10000) revert InvalidAmount(_amount);
        uint32 _paymentDue = uint32(block.timestamp) + _borrowPeriod;
        leverages[_msgSender()] = LeverageInfo(_leverage.totalStaked, _amount, borrowAPY, uint32(block.timestamp), _paymentDue);
        // TODO: transfer borrow amount from treasury
        emit Borrowed(_msgSender(), _amount, _paymentDue);
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
        notZeroAddress(_account)
    {
        _grantRole(role, _account);
    }

    function revokeRole(bytes32 role, address _account)
        public
        override
        onlyRole(getRoleAdmin(role))        
        notZeroAddress(_account)
    {
        _revokeRole(role, _account);
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}