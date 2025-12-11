# EduLoan - Mantle Co-Learning Camp Challenge

## Author
- Nama: M Daffa Al Ghifary
- GitHub: alghifarydaffa62
- Wallet: 0xdfa064288176054574649e0f4c77eaf413351767

## Contract Address (Mantle Sepolia)
`0x679035fA6e592EE5D4D0E5650404c3FB940d9De8`

## Features Implemented
- [✅] Apply Loan (With Interest Calculation)
- [✅] Approve/Reject Loan (Admin Only)
- [✅] Disburse Loan (With Reentrancy Guard)
- [✅] Make Payment (Partial & Full Payment)
- [✅] Check Default (Deadline Validation)
- [✅] Bonus: Overpayment Refund Protection (Mengembalikan kelebihan bayar otomatis)
- [✅] Bonus: Admin Liquidity Management (Deposit & Withdraw Funds)

## Screenshots
- berada di folder screenshots

## How to Test
1. Deploy contract di Mantle Sepolia
2. Admin deposit funds
3. User apply loan
4. Admin approve loan
5. Admin disburse loan
6. User make payment

## Lessons Learned

Throughout the development of the EduLoan smart contract, I gained deep insights into several critical aspects of Solidity and DeFi logic:

1.  **Precision in Access Control:**
    I learned the critical importance of logic operators in modifiers. A small mistake (like swapping `==` with `!=`) in the `onlyAdmin` modifier can completely compromise the contract's security. Unit testing is essential to catch these logical inversions.

2.  **Financial UX & Refund Logic:**
    Handling raw ETH/MNT requires careful user experience design. I implemented a **Refund Mechanism** in the `makePayment` function. If a user accidentally sends more than their remaining debt, the contract calculates the difference and automatically refunds the excess amount, ensuring no user funds are lost.

3.  **Integer Math & Basis Points:**
    Since Solidity does not support floating-point numbers, I learned to use **Basis Points** (e.g., 500 for 5%) for interest rate calculations to maintain precision. I also gained a better understanding of handling units like `Wei` vs `Ether` to prevent underflow/overflow errors.

4.  **Checks-Effects-Interactions Pattern:**
    In the `disburseLoan` function, I applied the Checks-Effects-Interactions pattern. By updating the loan status *before* transferring the funds to the borrower, I ensured the contract is safer against potential reentrancy attacks.

5.  **Mantle Network Deployment:**
    I successfully configured Remix IDE with MetaMask to deploy and verify the contract on the **Mantle Sepolia Testnet**, understanding the flow of gas fees and transaction confirmation on Layer 2.