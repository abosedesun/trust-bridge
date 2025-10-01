# TrustBridge Protocol

**A decentralized escrow and reputation system for peer-to-peer transactions on Bitcoin Layer 2**

---

## Overview

**TrustBridge Protocol** enables secure and transparent peer-to-peer (P2P) transactions through a combination of **escrowed payments** and **on-chain reputation scoring**. Built natively for the **Stacks blockchain**, the protocol leverages Bitcoin’s finality and security while extending it with programmable smart contracts in **Clarity**.

TrustBridge addresses the fundamental challenge of **trust in P2P markets**:

* Counterparties are protected by escrow during settlement.
* Reputation scores accumulate on-chain to incentivize honest behavior.
* All interactions are fully auditable and tamper-resistant.

---

## Key Features

* **Escrowed Payments**: Funds are securely locked until conditions are met and counterparties confirm.
* **Reputation Tracking**: Each user builds a verifiable trust score based on their historical transaction outcomes.
* **Fraud Mitigation**: Self-deals and invalid counterparties are prevented by validation logic.
* **Lightweight Settlement**: Simple initiation, payment, and rating flows for frictionless adoption.
* **Bitcoin Anchoring**: Security and settlement finality backed by Bitcoin via Stacks.

---

## System Overview

The TrustBridge system consists of three primary modules:

1. **Deal Management**

   * Allows users to initiate P2P agreements.
   * Tracks counterparties, deal value, and state (`OPEN`, completed, etc.).

2. **Escrowed Payments**

   * Handles STX transfers through locked payment records.
   * Ensures funds are only moved when both parties fulfill conditions.

3. **Reputation Profiles**

   * Aggregates ratings from completed deals.
   * Builds trust scores based on historical performance.
   * Provides queryable trust history for any user.

---

## Contract Architecture

The Clarity smart contract is structured around **core state maps** and **workflow functions**:

### Data Maps

* **`payments`**: Escrow records linking initiator → counterparty, with amount and completion status.
* **`deals`**: Transaction metadata including initiator, counterparty, value, timestamp, and trust score.
* **`trust-profiles`**: Reputation profiles with cumulative score and deal count for each user.

### Public Functions

* **`initiate-deal(counterparty, value)`**

  * Opens a new deal and creates corresponding escrow/payment records.

* **`complete-payment(payment-id)`**

  * Executes the STX transfer and marks the escrow as complete.

* **`rate-counterparty(deal-id, rating)`**

  * Updates trust score of initiator based on counterparty’s rating.

### Read-Only Functions

* **`get-trust-profile(address)`** → Returns user’s trust stats.
* **`get-payment-info(payment-id)`** → Returns escrow/payment details.
* **`get-deal-info(deal-id)`** → Returns deal metadata.

---

## Data Flow

**Step 1 – Initiate Deal**

1. User A calls `initiate-deal(User B, value)`.
2. Contract records a new `payment` and `deal` entry.
3. Funds are locked until deal completion.

**Step 2 – Complete Payment**

1. User A executes `complete-payment(payment-id)`.
2. STX are transferred from User A → User B.
3. Payment status is updated to `complete`.

**Step 3 – Reputation Rating**

1. User B calls `rate-counterparty(deal-id, rating)`.
2. Contract updates User A’s trust profile (cumulative score + deal count).
3. Deal record is updated with the rating.

---

## Access Control & Security

* **Contract Owner/Admin**: Defined at deployment, used for privileged checks.
* **Validation Guards**: Prevent self-deals, zero-value transfers, or unauthorized rating.
* **Immutable Trust Records**: All ratings and deal data are permanently stored on-chain.

---

## Example Usage

```clarity
;; Initiate a new deal of 100 STX with Alice
(contract-call? .trustbridge initiate-deal 'ST123...Alice u100)

;; Complete the payment once conditions are met
(contract-call? .trustbridge complete-payment u1)

;; Counterparty rates initiator after successful deal
(contract-call? .trustbridge rate-counterparty u1 u5)

;; Retrieve Alice’s trust profile
(contract-call? .trustbridge get-trust-profile 'ST123...Alice)
```

---

## Future Extensions

* **Multi-signature escrow support** for more complex deal structures.
* **Dispute resolution mechanisms** via decentralized arbitration.
* **Weighted trust scoring** based on deal value or time decay.
* **Cross-contract composability** with lending, marketplaces, and other DeFi primitives.

---

## License

MIT License. Open for community collaboration and improvement.
