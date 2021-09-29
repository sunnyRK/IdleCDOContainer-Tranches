pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TrancheERC20/AATranche.sol";
import "./TrancheERC20/BBTranche.sol";
import "./access/AssetManager.sol";
import "./interfaces/IIdleCDO.sol";

contract IdleCDOContainer is Initializable, ReentrancyGuardUpgradeable, AATranche, BBTranche, AssetManager {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public underlyingToken;

    address[] public CDOs;
    mapping (address => uint256) public SplitRatio;

    event IdleCDOContainerInitialized(address _underlyingToken);
    event DepositAA(address account, uint256 amount);
    event DepositBB(address account, uint256 amount);
    event WithdrawAA(address account, uint256 amount);
    event WithdrawBB(address account, uint256 amount);
    event TransferredERC20(address indexed from, address indexed to, uint256 amount, address indexed token);

    function initialize(
        address _underlyingToken
    ) public initializer {

        __Ownable_init();
        __AA__ERC20_init('AA_IdleCDOShare', 'AA_ICDO');
        __BB__ERC20_init('BB_IdleCDOShare', 'BB_ICDO');
        __ReentrancyGuard_init();

        underlyingToken = IERC20Upgradeable(_underlyingToken);

        emit IdleCDOContainerInitialized(_underlyingToken);
    }

    function addCDOs(address[] memory _CDOs) public onlyOwnerOrAssetManager {
        require(_CDOs.length > 0, "IdleCDOContainer: Insufficient Data");
        CDOs = _CDOs;
        for(uint i=0; i<CDOs.length; i++) {
            underlyingToken.safeApprove(CDOs[i], type(uint256).max);
        }
    }

    function setRatio(uint256[] memory _ratio) public onlyOwnerOrAssetManager {
        require(CDOs.length == _ratio.length, "IdleCDOContainer: Insufficient Data");
        uint256 _totalRatio;
        for (uint i=0; i<CDOs.length; i++) {
            SplitRatio[CDOs[i]] =  _ratio[i];
            _totalRatio += _ratio[i];
        }
        require(_totalRatio == 100, "IdleCDOContainer: Unstable Ratio");
    }

    function depositAA(uint256 _amount) public nonReentrant {
        require(_amount > 0, "IdleCDOContainer: Amount should not be ZERO");
        
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        AA_mint(msg.sender, _amount);
        emit DepositAA(msg.sender, _amount);
    }

    function depositBB(uint256 _amount) public nonReentrant {
        require(_amount > 0, "IdleCDOContainer: Amount should not be ZERO");
        
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        BB_mint(msg.sender, _amount);
        emit DepositBB(msg.sender, _amount);
    }


    function withdrawAA(uint256 _amount) public nonReentrant {
        require(_amount > 0, "IdleCDOContainer: Amount should not be ZERO");
        require(AA_balanceOf(msg.sender) >= _amount, "IdleCDOContainer: Low Balance");
        
        _withdrawAA(_amount);
        emit WithdrawAA(msg.sender, _amount);
    }

    function withdrawBB(uint256 _amount) public nonReentrant {
        require(_amount > 0, "IdleCDOContainer: Amount should not be ZERO");
        require(BB_balanceOf(msg.sender) >= _amount, "IdleCDOContainer: Low Balance");

        _withdrawBB(_amount);
        emit WithdrawBB(msg.sender, _amount);
    }

    function _withdrawAA(uint256 _amountToWithdraw) internal virtual {
        uint256 currentBalance = underlyingToken.balanceOf(address(this));
        if (currentBalance < _amountToWithdraw) {

            uint256 _toWithdraw = _amountToWithdraw - currentBalance;

            for ( uint i=0; i<CDOs.length; i++) {
                if (SplitRatio[CDOs[i]] > 0) {
                    uint w = ( SplitRatio[CDOs[i]] * _toWithdraw ) / 100;
                    IIdleCDO(CDOs[i]).withdrawAA(w);
                }
            }

            uint256 _after = underlyingToken.balanceOf(address(this));
            uint256 _diff = _after - currentBalance;
            if (_diff < _toWithdraw) {
                _amountToWithdraw = currentBalance + _diff;
            }
        }

        AA_burn(msg.sender, _amountToWithdraw);

        underlyingToken.safeTransfer(msg.sender, _amountToWithdraw);
    }

    function _withdrawBB(uint256 _amountToWithdraw) internal virtual {
        uint256 currentBalance = underlyingToken.balanceOf(address(this));
        if (currentBalance < _amountToWithdraw) {

            uint256 _toWithdraw = _amountToWithdraw - currentBalance;

            for ( uint i=0; i<CDOs.length; i++) {
                if (SplitRatio[CDOs[i]] > 0) {
                    uint w = ( SplitRatio[CDOs[i]] * _toWithdraw ) / 100;
                    IIdleCDO(CDOs[i]).withdrawBB(w);
                }
            }

            uint256 _after = underlyingToken.balanceOf(address(this));
            uint256 _diff = _after - currentBalance;
            if (_diff < _toWithdraw) {
                _amountToWithdraw = currentBalance + _diff;
            }
        }

        BB_burn(msg.sender, _amountToWithdraw);

        underlyingToken.safeTransfer(msg.sender, _amountToWithdraw);
    }

    function earnAA() public onlyOwnerOrAssetManager {
        uint256 balance = AA_balanceOf(address(this));
        require(balance > 0, "IdleCDOContainer: Amount should not be ZERO");
        for ( uint i=0; i<CDOs.length; i++) {
            if (SplitRatio[CDOs[i]] > 0) {
                uint amt = ( SplitRatio[CDOs[i]] * balance ) / 100;
                IIdleCDO(CDOs[i]).depositAA(amt);
            }
        }
    }

    function earnBB() public onlyOwnerOrAssetManager {
        uint256 balance = BB_balanceOf(address(this));
        require(balance > 0, "IdleCDOContainer: Amount should not be ZERO");
        for ( uint i=0; i<CDOs.length; i++) {
            if (SplitRatio[CDOs[i]] > 0) {
                uint amt = ( SplitRatio[CDOs[i]] * balance ) / 100;
                IIdleCDO(CDOs[i]).depositBB(amt);
            }
        }
    }

    function transferERC20(address erc20Token, address to, uint256 amount) external onlyOwnerOrAssetManager {
        require(erc20Token != address(underlyingToken), "IdleCDOContainer: Address can't be underlying");
        IERC20Upgradeable(erc20Token).safeTransfer(to, amount);
        emit TransferredERC20(msg.sender, to, amount, erc20Token);
    }
}
