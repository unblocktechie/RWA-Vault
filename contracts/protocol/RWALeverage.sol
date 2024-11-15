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
    PoolStatus public status;
    mapping(address => StakeInfo[]) public stakes;

    struct StakeInfo {
        uint256 amount;
        uint32 lockTime;
        uint32 unlockTime;
        bool isUnstaked;        
    }
    
    enum PoolStatus {PENDING, ACTIVE, CLOSE}

    event AdminTransferred(address _oldOwner, address _newOwner);
    event PoolStatusUpdated(PoolStatus _prevStatus, PoolStatus _newStatus);
    event Staked(address indexed _staker, uint256 _amount, uint256 _index);
    event Unstaked(address indexed _staker, uint256 _amount, uint256 _index);
    event SlicePeriodUpdated(uint32 _prevValue, uint256 _newValue);
    event MinMaxStakeDurationUpdated(uint32 _min, uint32 _max, uint32 _newMin, uint32 _newMax);

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
    
    function stake(uint256 _amount, uint32 _lockingPeriodInSeconds) external {
        if(_amount == 0 || (_lockingPeriodInSeconds % slice != 0) || (_lockingPeriodInSeconds < minStakeDurationAllowed) || (_lockingPeriodInSeconds > maxStakeDurationAllowed)) {
            revert InvalidInputs(_amount, _lockingPeriodInSeconds);
        }
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(rwaToken), _msgSender(), address(this), _amount);
        uint32 _unlockTime = uint32(block.timestamp) + _lockingPeriodInSeconds;
        emit Staked(_msgSender(), _amount, stakes[_msgSender()].length);
        stakes[_msgSender()].push(StakeInfo(_amount, uint32(block.timestamp), _unlockTime, false));
    }

    function unStake(uint256 _index) external {
        if(status != PoolStatus.ACTIVE) revert PoolIsNotActive();
        StakeInfo memory _stake = stakes[_msgSender()][_index];
        if(_stake.isUnstaked) revert AlreadyUnstaked(_msgSender(), _index);
        if(block.timestamp < _stake.unlockTime) revert NotUnlocked(_msgSender());
        stakes[_msgSender()][_index].isUnstaked = true;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(rwaToken), _msgSender(), _stake.amount);
        emit Unstaked(_msgSender(), _stake.amount, _index);
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