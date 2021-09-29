pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract AATranche is ERC20Upgradeable {

    function __AA__ERC20_init(string memory name_, string memory symbol_) internal {
        __ERC20_init(name_, symbol_);
    }

    function AA_name() public view returns (string memory) {
        return name();
    }

    function AA_symbol() public view returns (string memory) {
        return symbol();
    }

    function AA_decimals() public view returns (uint8) {
        return decimals();
    }

    function AA_totalSupply() public view returns(uint256) {
        return totalSupply();
    }

    function AA_balanceOf(address account) public view returns(uint256) {
        return balanceOf(account);
    }

    function AA_allownace(address owner, address spender) public view returns(uint256) {
        return allowance(owner, spender);
    }

    function AA_mint(address account, uint256 amount) internal {
        _mint(account, amount);
    }

    function AA_burn(address account, uint256 amount) internal {
        _burn(account, amount);
    }
}
