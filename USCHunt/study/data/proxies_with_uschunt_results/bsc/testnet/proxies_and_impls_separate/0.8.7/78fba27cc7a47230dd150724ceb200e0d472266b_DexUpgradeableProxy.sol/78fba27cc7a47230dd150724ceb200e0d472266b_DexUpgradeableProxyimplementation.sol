/**
 *Submitted for verification at BscScan.com on 2022-03-07
*/

// : MIT
pragma solidity ^0.8.7;



interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function __Ownable_init() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
}

abstract contract Pausable is Initializable, Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function __Pausable_init() internal onlyInitializing {
        _paused = false;
    }
}

abstract contract ReentrancyGuard is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract OvalRegularPledge is Initializable, Ownable, Pausable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    // PledgePool[] private pools;
    uint256 private primaryId;
    uint256 private lockDuration;
    address private token;
    uint256[] private tmpIds;
    uint256[] private poolIds;
    mapping(uint256 => PledgePool) private poolMap; // PoolId => PledgePool
    mapping(uint256 => uint256) private removedIdMap; // PledgeId => PoolId
    mapping(uint256 => mapping(address => Collect[])) private principleMap;
    mapping(uint256 => mapping(address => Collect[])) private interestMap;

    struct PledgePool {
        uint256 id;
        uint256 startTime;
        uint256 duration;
    }

    struct Collect {
        uint256 id;
        uint256 amount;
        uint256 deadline;
        uint256 poolId;
    }

    struct AirdropItem {
        uint256[] pledgeIds;
        address wallet;
        uint256 amount;
        uint256 poolId;
    }

    event Pledge (
        address from,
        uint256 amount,
        uint256 id,
        uint256 poolId,
        uint256 startTime,
        uint256 deadline
    );

    event ClaimPrinciple (
        address token,
        address from,
        address to,
        uint256 amount
    );

    event ClaimInterest (
        address token,
        address from,
        address to,
        uint256 amount
    );

    event Withdraw (
        address token,
        address from,
        address to,
        uint256 amount
    );

    function __OvalRegularPledge_init() private {
        lockDuration = 2592000;
        primaryId = 0;

        uint256 firstPoolId = autoIncrementId();
        poolMap[firstPoolId] = PledgePool(firstPoolId, 1672378757, 5184000);

        uint256 secondPoolId = autoIncrementId();
        poolMap[secondPoolId] = PledgePool(secondPoolId, 1672378757, 10368000);
        poolIds = [firstPoolId, secondPoolId];
    }

    function initialize() external initializer {
        __OvalRegularPledge_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        require(owner() != address(0), "new owner is the zero address");
    }

    modifier validPoolId(uint256 poolId) {
        require(poolMap[poolId].duration > 0 && poolMap[poolId].id == poolId, "Invalid pool Id");
        _;
    }

    //  Set lock-up duration
    function setLockDuration(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
    }

    //  Set the token under the IBEP20 protocol
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        token = _token;
    }

    // modify pool duration
    function changeDuration(uint256 poolId, uint256 _duration) external validPoolId(poolId) onlyOwner {
        require(poolMap[poolId].startTime > block.timestamp, "Activity has started");
        // require(31536000 >= _duration && _duration >= 86400, "Invalid duration");
        require(_duration > 60, "Invalid duration");
        poolMap[poolId].duration = _duration;
    }

    // modify pool start time
    function changeStartTime(uint256 poolId, uint256 _startTime) external validPoolId(poolId) onlyOwner {
        require(poolMap[poolId].startTime > block.timestamp, "Activity has started");
        require(_startTime > 0, "Invalid start time");
        poolMap[poolId].startTime = _startTime;
    }

    /**
     * Pledge, index: the subscript of durations
     */
    function pledge(uint256 amount, uint256 poolId) external whenNotPaused validPoolId(poolId) nonReentrant {
        require(poolMap[poolId].startTime <= block.timestamp, "Activity has not started");
        require(amount >= (10 ** (IBEP20(token).decimals() + 1)), "Pledge amount can't less than 10");
        require(token != address(0), "Invalid token address");
        IBEP20(token).safeTransferFrom(_msgSender(), address(this), amount);

        uint256 identifier = autoIncrementId();
        uint256 deadline = getDeadline(poolMap[poolId].duration);
        principleMap[poolId][_msgSender()].push (
            Collect(
                identifier,
                amount,
                deadline,
                poolId
            )
        );
        emit Pledge(_msgSender(), amount, identifier, poolId, block.timestamp, deadline);
    }

    /**
     * group airdrop: the interests of Pledge
     */
    function groupAirdrop(AirdropItem[] calldata items) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < items.length; i++) {
            require(items[i].wallet != address(0), "Invalid token address");
            require(items[i].pledgeIds.length > 0, "Target 'id' not found");
            require(items[i].amount > 0, "Reward amount can't be zero");
            airdrop(items[i]);
        }
    }

    /**
     * single airdrop: the interest of Pledge
     */
    function airdrop(AirdropItem calldata item) private {
        require(item.poolId <= primaryId, "Invalid Identifier");
        uint256 interestId = autoIncrementId();
        interestMap[item.poolId][item.wallet].push(
            Collect(
                interestId,
                item.amount,
                getDeadline(lockDuration),
                item.poolId
            )
        );
    }

    /**
    * Claim the interest due by 'id'
    */
    function claimPrinciple(uint256 pledgeId, uint256 poolId) external whenNotPaused validPoolId(poolId) nonReentrant {
        require(pledgeId > 0 && pledgeId <= primaryId, "Invalid id");
        require(token != address(0), "Invalid token address");
        uint256 _index;
        bool isExits = false;
        for (uint256 j = 0; j < principleMap[poolId][_msgSender()].length; j++) {
            if (principleMap[poolId][_msgSender()][j].id == pledgeId && principleMap[poolId][_msgSender()][j].deadline <= block.timestamp) {
                _index = j;
                isExits = true;
                break;
            }
        }
        require(isExits, "The target 'id' not found");
        uint256 amount = principleMap[poolId][_msgSender()][_index].amount;
        IBEP20(token).safeTransfer(_msgSender(), amount);
        deletePrinciple(_index, poolId);
        emit ClaimPrinciple(token, address(this), _msgSender(), amount);
    }

    /**
    * Claim all of the principle due
    */
    function claimAllDuePrinciple(uint256 poolId) external whenNotPaused validPoolId(poolId) nonReentrant {
        require(poolMap[poolId].startTime <= block.timestamp, "Activity has not started");
        uint256 dueAmount = 0;
        uint256 count = 0;
        for (uint256 j = 0; j < principleMap[poolId][_msgSender()].length; j++) {
            if (principleMap[poolId][_msgSender()][j].deadline <= block.timestamp) {
                if (count > 300) {
                    break;
                }
                removedIdMap[principleMap[poolId][_msgSender()][j].id] = j;
                tmpIds.push(principleMap[poolId][_msgSender()][j].id);
                count = count.add(1);
                dueAmount = dueAmount.add(principleMap[poolId][_msgSender()][j].amount);
            }
        }
        require(tmpIds.length > 0 && dueAmount > 0, "No expired reward found");
        IBEP20(token).safeTransfer(_msgSender(), dueAmount);

        while(tmpIds.length > 0) {
            uint256 index = removedIdMap[tmpIds[tmpIds.length-1]];
            deletePrinciple(index, poolId);
            tmpIds.pop();
        }
        emit ClaimPrinciple(token, address(this), _msgSender(), dueAmount);
    }

    function deletePrinciple(uint256 index, uint256 poolId) private {
        require(index < principleMap[poolId][_msgSender()].length, "arrays index out of bounds");
        uint256 length = principleMap[poolId][_msgSender()].length;
        for (uint256 i = index; i < length - 1; i++) {
            principleMap[poolId][_msgSender()][i] = principleMap[poolId][_msgSender()][i + 1];
        }
        principleMap[poolId][_msgSender()].pop();
    }

    /**
     * Claim all available interest
     */
    function claimAllDueInterest(uint256 poolId) external whenNotPaused validPoolId(poolId) nonReentrant {
        require(token != address(0), "Invalid token address");
        uint256 dueAmount;
        uint256 count = 0;
        for (uint256 j = 0; j < interestMap[poolId][_msgSender()].length; j++) {
            if (interestMap[poolId][_msgSender()][j].deadline <= block.timestamp) {
                if (count > 300) {
                    break;
                }
                removedIdMap[interestMap[poolId][_msgSender()][j].id] = j;
                tmpIds.push(interestMap[poolId][_msgSender()][j].id);
                count = count + 1;
                dueAmount = dueAmount.add(interestMap[poolId][_msgSender()][j].amount);
            }
        }
        require(dueAmount > 0, "No expired reward found");
        IBEP20(token).safeTransfer(_msgSender(), dueAmount);

        while(tmpIds.length > 0) {
            uint256 index = removedIdMap[tmpIds[tmpIds.length-1]];
            deleteInterest(index, poolId);
            tmpIds.pop();
        }
 
        emit ClaimInterest(token, address(this), _msgSender(), dueAmount);
    }

    /**
     * Claim the interest due by 'ids'
     */
    function claimInterest(uint256 interestId, uint256 poolId) external whenNotPaused validPoolId(poolId) nonReentrant {

        require(token != address(0), "Invalid token address");
        uint256 _index;
        bool isExits;
        for (uint256 j = 0; j < interestMap[poolId][_msgSender()].length; j++) {
            if (interestMap[poolId][_msgSender()][j].id == interestId && interestMap[poolId][_msgSender()][j].deadline <= block.timestamp) {
                _index = j;
                isExits = true;
                break;
            }
        }
        require(isExits, "The target 'id' not found");
        uint256 amount = interestMap[poolId][_msgSender()][_index].amount;
        IBEP20(token).safeTransfer(_msgSender(), amount);
        deleteInterest(_index, poolId);
        emit ClaimInterest(token, address(this), _msgSender(), amount);
    }

    function deleteInterest(uint256 index, uint256 poolId) internal {
        require(index < interestMap[poolId][_msgSender()].length, "arrays index out of bounds");
        uint256 length = interestMap[poolId][_msgSender()].length;
        for (uint256 i = index; i < length - 1; i++) {
            interestMap[poolId][_msgSender()][i] = interestMap[poolId][_msgSender()][i + 1];
        }
        interestMap[poolId][_msgSender()].pop();
    }

    /**
     * withdraw by owner only
     */
    function withdraw(address _token, uint256 amount) external onlyOwner whenNotPaused {
        require(_token != address(0), "Invalid token address");
        require(amount > 0, "Withdraw amount can't be zero");
        IBEP20(_token).safeTransfer(_msgSender(), amount);
        emit Withdraw(_token, address(this), _msgSender(), amount);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function getPrincipleLength(uint256 poolId) external validPoolId(poolId) view returns (uint256) {
        return principleMap[poolId][_msgSender()].length;
    }

    function getInterestLength(uint256 poolId) external validPoolId(poolId) view returns (uint256) {
        return interestMap[poolId][_msgSender()].length;
    }

    function getPrincipleRecord(uint256 index, uint256 poolId) external validPoolId(poolId) view returns (uint256, uint256, uint256) {
        require(index < principleMap[poolId][_msgSender()].length, "Record not found");
        return (
            principleMap[poolId][_msgSender()][index].id,
            principleMap[poolId][_msgSender()][index].amount,
            principleMap[poolId][_msgSender()][index].deadline
        );
    }

    function getInterestRecord(uint256 index, uint256 poolId) external validPoolId(poolId) view returns (uint256, uint256, uint256) {
        require(index < interestMap[poolId][_msgSender()].length, "Record not found");
        return (
            interestMap[poolId][_msgSender()][index].id,
            interestMap[poolId][_msgSender()][index].amount,
            interestMap[poolId][_msgSender()][index].deadline
        );
    }

    function getPoolsLength() external view returns (uint256) {
        return poolIds.length;
    }

    function getPoolId(uint256 poolIndex) external view returns (uint256) {
        require(poolIndex < poolIds.length, "Index out of bounds");
        return poolIds[poolIndex];
    }

    function getPoolInfo(uint256 poolId) external validPoolId(poolId) view returns (uint256, uint256, uint256) {
        return (
            poolMap[poolId].id, 
            poolMap[poolId].startTime, 
            poolMap[poolId].duration
        );
    }

    function autoIncrementId() private returns (uint256) {
        return primaryId += 1;
    }

    function getDeadline(uint256 duration) private view returns (uint256) {
        return block.timestamp.add(duration);
    }
}