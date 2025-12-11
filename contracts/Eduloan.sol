// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title EduLoan - Decentralized Student Loan System
/// @author M Daffa Al Ghifary
/// @notice Sistem pinjaman pendidikan terdesentralisasi di Mantle Network
/// @dev Challenge Final Mantle Co-Learning Camp

contract Eduloan {
    // ============================================
    // ENUMS & STRUCTS
    // ============================================

    enum LoanStatus {
        Pending,
        Approved,
        Active,
        Repaid,
        Defaulted,
        Rejected
    }

    struct Loan {
        uint256 loanId;
        address borrower;
        uint256 principalAmount;
        uint256 interestRate;
        uint256 totalAmount;
        uint256 amountRepaid;
        uint256 applicationTime;
        uint256 approvalTime;
        uint256 deadline;
        LoanStatus status;
        string purpose;
    }

    // ============================================
    // STATE VARIABLES
    // ============================================

    address public admin;
    uint public loanCounter;
    uint public constant INTEREST_RATE = 500;
    uint public constant LOAN_DURATION = 365 days;
    uint public constant MIN_LOAN = 0.01 ether;
    uint public constant MAX_LOAN = 10 ether;

    mapping(uint => Loan) public loans;
    mapping(address => uint[]) public borrowerLoans;

    // ============================================
    // EVENTS
    // ============================================

    // TODO: Deklarasikan semua events
    event LoanApplied(uint256 indexed loanId, address indexed borrower, uint256 amount, string purpose);
    event LoanApproved(uint256 indexed loanId, address indexed borrower, uint256 totalAmount);
    event LoanRejected(uint256 indexed loanId, address indexed borrower, string reason);
    event LoanDisbursed(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event PaymentMade(uint256 indexed loanId, address indexed borrower, uint256 amount, uint256 remaining);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower);
    event LoanDefaulted(uint256 indexed loanId, address indexed borrower);

    // ============================================
    // MODIFIERS
    // ============================================

    // TODO: Buat modifiers (onlyAdmin, onlyBorrower, dll)
    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin!");
        _;
    }

    modifier onlyBorrower(uint256 loanId) {
        require(msg.sender == loans[loanId].borrower, "You are not the borrower!");
        _;
    }

    modifier loanExist(uint256 loanId) {
        require(loanId > 0 && loanId <= loanCounter, "Loan doesn't exist");
        _;
    }

    modifier inStatus(uint256 _loanId, LoanStatus _status) {
        require(loans[_loanId].status == _status, "Invalid loan status");
        _;
    }

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor() {
        admin = msg.sender;
    }

    // ============================================
    // MAIN FUNCTIONS
    // ============================================

    /// @notice Mahasiswa mengajukan pinjaman
    /// @param _amount Jumlah pinjaman yang diajukan
    /// @param _purpose Tujuan pinjaman
    function applyLoan(uint256 _amount, string memory _purpose) public {
        require(_amount >= MIN_LOAN && _amount <= MAX_LOAN, "Loan Amount invalid!");
        loanCounter++;

        uint _loanId = loanCounter;
        uint interest = (_amount * INTEREST_RATE) / 10000;
        uint total = _amount + interest;

        loans[loanCounter] = Loan({
            loanId: _loanId,
            borrower: msg.sender,
            principalAmount: _amount,
            interestRate: INTEREST_RATE,
            totalAmount: total,
            amountRepaid: 0,
            applicationTime: block.timestamp,
            approvalTime: 0,
            deadline: 0,
            status: LoanStatus.Pending,
            purpose: _purpose
        });

        borrowerLoans[msg.sender].push(_loanId);

        emit LoanApplied(_loanId, msg.sender, _amount, _purpose);
    }

    /// @notice Admin menyetujui pinjaman
    /// @param _loanId ID pinjaman yang disetujui
    function approveLoan(uint256 _loanId) public onlyAdmin loanExist(_loanId) inStatus(_loanId, LoanStatus.Pending) {
        Loan storage loan = loans[_loanId];
        loan.approvalTime = block.timestamp;
        loan.status = LoanStatus.Approved;

        emit LoanApproved(_loanId, loan.borrower, loan.totalAmount);
    }

    /// @notice Admin menolak pinjaman
    /// @param _loanId ID pinjaman yang ditolak
    /// @param _reason Alasan penolakan
    function rejectLoan(uint256 _loanId, string memory _reason) public onlyAdmin loanExist(_loanId) inStatus(_loanId, LoanStatus.Pending) {
        Loan storage loan = loans[_loanId];
        loan.status = LoanStatus.Rejected;

        emit LoanRejected(_loanId, loan.borrower, _reason);
    }

    /// @notice Admin mencairkan dana pinjaman
    /// @param _loanId ID pinjaman yang dicairkan
    function disburseLoan(uint256 _loanId) public onlyAdmin loanExist(_loanId) inStatus(_loanId, LoanStatus.Approved) {
        Loan storage loan = loans[_loanId];
        uint amount = loan.principalAmount;

        require(address(this).balance >= amount, "Contract balance insuffcient!");

        loan.deadline = block.timestamp + LOAN_DURATION;
        loan.status = LoanStatus.Active;

        (bool success, ) = loan.borrower.call{value: amount}("");
        require(success, "Loan Transfer failed!");

        emit LoanDisbursed(_loanId, loan.borrower, amount);
    }

    /// @notice Borrower membayar cicilan
    /// @param _loanId ID pinjaman
    function makePayment(uint256 _loanId) public payable onlyBorrower(_loanId) loanExist(_loanId) inStatus(_loanId, LoanStatus.Active) {
        require(msg.value > 0, "Insufficient Payment amount");
        Loan storage loan = loans[_loanId];

        uint remaining = loan.totalAmount - loan.amountRepaid;
        uint paymentAmount = msg.value;
        uint refundAmount = 0;

        if (paymentAmount > remaining) {
            refundAmount = paymentAmount - remaining;
            paymentAmount = remaining;
        }

        loan.amountRepaid += paymentAmount;

        uint currentRemaining = loan.totalAmount - loan.amountRepaid;

        if(loan.amountRepaid >= loan.totalAmount) {
            loan.status = LoanStatus.Repaid;
            emit LoanRepaid(_loanId, loan.borrower);
        }

        emit PaymentMade(_loanId, loan.borrower, paymentAmount, currentRemaining);

        if (refundAmount > 0) {
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
   }

    /// @notice Cek apakah pinjaman sudah default
    /// @param _loanId ID pinjaman
    function checkDefault(uint256 _loanId) public loanExist(_loanId) {
        Loan storage loan = loans[_loanId];

        if(loan.status == LoanStatus.Active) {
            if(block.timestamp > loan.deadline) {
                loan.status = LoanStatus.Defaulted;
                emit LoanDefaulted(_loanId, loan.borrower);
            }
        }
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /// @notice Lihat detail pinjaman
    function getLoanDetails(uint256 _loanId) public view returns (Loan memory) {
        return loans[_loanId];
    }

    /// @notice Lihat semua pinjaman milik caller
    function getMyLoans() public view returns (uint256[] memory) {
        return borrowerLoans[msg.sender];
    }

    /// @notice Hitung bunga dari principal
    function calculateInterest(uint256 _principal) public pure returns (uint256) {
        return (_principal * INTEREST_RATE) / 10000;
    }

    /// @notice Lihat sisa yang harus dibayar
    function getRemainingAmount(uint256 _loanId) public view returns (uint256) {
        Loan memory loan = loans[_loanId];
        if (loan.status == LoanStatus.Repaid) return 0;
        return loan.totalAmount - loan.amountRepaid;
    }

    /// @notice Lihat saldo contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ============================================
    // ADMIN FUNCTIONS
    // ============================================

    /// @notice Admin deposit dana ke contract
    function depositFunds() public payable onlyAdmin {
        require(msg.value > 0, "Insufficient deposit amount");
    }

    /// @notice Admin withdraw dana dari contract
    function withdrawFunds(uint256 _amount) public onlyAdmin {
        require(_amount > 0 && _amount <= address(this).balance, "Insufficient withdraw amounts");

        (bool success, ) = admin.call{value: _amount}("");
        require(success, "Withdraw failed!");
    }
}