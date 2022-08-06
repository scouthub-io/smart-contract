// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ERC20 Token for ScoutHub
 * @author 0xVeliUysal, 0xfunTalia, Dozcan, ScoutHUB and Deneth
 */
contract ScoutHUBToken is Context, IERC20, IERC20Metadata, Ownable, Pausable {
    string public constant name = "ScoutHUB Token"; //  ScoutHUB Project
    string public constant symbol = "HUB"; // our ticker is HUB
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1_000_000_000 ether; // total supply is 1,000,000,000
    uint256 private maxSupply = 1_250_000_000 ether; // maximum supply is 1,250,000,000

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // This is a map of addresses to cooldown times and is triggered on every transfer.
    mapping(address => uint32) private cooldowns;
    // Some addresses should never have a cooldown, such as exchange addresses. Those can be added here.
    mapping(address => bool) private cooldownWhitelist;
    uint256 public MEV_COOLDOWN_TIME = 1 minutes;

    event Mint(address indexed minter, address indexed account, uint256 amount);
    event Burn(address indexed burner, address indexed account, uint256 amount);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    /**
     * @notice toggle pause
     * This method using for toggling pause for contract
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 value)
        external
        whenNotPaused
        returns (bool)
    {
        require(to != address(0), "ERC20: to address is not valid");
        require(value <= balances[msg.sender], "ERC20: insufficient balance");

        beforeTokenTransfer(msg.sender);

        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;

        emit Transfer(msg.sender, to, value);

        afterTokenTransfer(to);

        return true;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        returns (uint256 balance)
    {
        return balances[account];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value)
        external
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused returns (bool) {
        require(from != address(0), "ERC20: from address is not valid");
        require(to != address(0), "ERC20: to address is not valid");
        require(value <= balances[from], "ERC20: insufficient balance");
        require(value <= allowed[from][msg.sender], "ERC20: from not allowed");

        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address account, address spender)
        external
        view
        whenNotPaused
        returns (uint256)
    {
        return allowed[account][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseApproval(address spender, uint256 addedValue)
        external
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][spender] =
            allowed[msg.sender][spender] +
            addedValue;

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseApproval(address spender, uint256 subtractedValue)
        external
        whenNotPaused
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][spender];

        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue - subtractedValue;
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @notice mint method
     * This method using to mint new hub tokens.
     */
    function mint(address to, uint256 amount) external whenNotPaused onlyOwner {
        require(to != address(0), "ERC20: to address is not valid");
        require(amount > 0, "ERC20: amount is not valid");

        uint256 totalAmount = totalSupply + amount;
        require(totalAmount <= maxSupply, "ERC20: unsufficient max supply");

        totalSupply = totalAmount;
        balances[to] = balances[to] + amount;

        emit Mint(msg.sender, to, amount);
    }

    /**
     * @notice burn method
     * This method is implemented for future business rules.
     */
    function burn(address account, uint256 amount) external whenNotPaused {
        require(account != address(0), "ERC20: from address is not valid");
        require(msg.sender == account, "ERC20: only your address");
        require(balances[account] >= amount, "ERC20: insufficient balance");

        balances[account] = balances[account] - amount;
        totalSupply = totalSupply - amount;
        maxSupply = maxSupply - amount;

        emit Burn(msg.sender, account, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     */
    function beforeTokenTransfer(
        address from
    ) internal virtual {
        // If the from address is not in the cooldown whitelist, verify it is not in the cooldown
        // period. If it is, prevent the transfer.
        if (!cooldownWhitelist[from]) {
            // Change the error message according to the customized cooldown time.
            require(
                cooldowns[from] <= uint32(block.timestamp),
                "Please wait before transferring or selling your tokens."
            );
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     */
    function afterTokenTransfer(
        address to
    ) internal virtual {
        // If the to address is not in the cooldown whitelist, add a cooldown to it.
        if (!cooldownWhitelist[to]) {
            // Add a cooldown to the address receiving the tokens.
            cooldowns[to] = uint32(block.timestamp + MEV_COOLDOWN_TIME);
        }
    }

    /**
     * Pass in an address to add it to the cooldown whitelist.
     */
    function addCooldownWhitelist(address whitelistAddy) external onlyOwner {
        cooldownWhitelist[whitelistAddy] = true;
    }

    /**
     * Pass in an address to remove it from the cooldown whitelist.
     */
    function removeCooldownWhitelist(address whitelistAddy) external onlyOwner {
        cooldownWhitelist[whitelistAddy] = false;
    }
    
    function setMEVCooldown(uint256 cooldown) external onlyOwner {
           MEV_COOLDOWN_TIME = cooldown;
    }

    /*
     * @notice fallback method
     *
     * executed when the `data` field is empty or starts with an unknown function signature
     */
    fallback() external {
        revert("Something bad happened");
    }
}
