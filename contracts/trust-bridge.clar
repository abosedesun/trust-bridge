;; Title: TrustBridge Protocol
;; 
;; Summary: A decentralized escrow and reputation system for peer-to-peer transactions on Bitcoin Layer 2
;;
;; Description: TrustBridge enables secure P2P deals through escrow mechanisms combined with an 
;; on-chain reputation scoring system. Users can initiate deals with counterparties, complete 
;; payments through the escrow, and build verifiable trust scores based on successful transaction 
;; history. The protocol incentivizes honest behavior through transparent reputation tracking while 
;; protecting both parties in bilateral agreements. Built natively for the Stacks blockchain to 
;; leverage Bitcoin's security with smart contract programmability.

;; ============================================
;; Constants - Access Control & Error Codes
;; ============================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ADMIN tx-sender)

;; Error codes
(define-constant ERR-NO-AUTH (err u1))
(define-constant ERR-LOW-VALUE (err u2))
(define-constant ERR-INVALID-USER (err u3))
(define-constant ERR-NO-PAYMENT (err u4))
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ZERO-AMOUNT (err u101))
(define-constant ERR-SELF-DEAL (err u102))
(define-constant ERR-DEAL-NOT-EXIST (err u103))
(define-constant ERR-BAD-RATING (err u104))
(define-constant ERR-INVALID-DEAL-ID (err u105))

;; ============================================
;; Data Variables
;; ============================================

(define-data-var payment-id-counter uint u1)
(define-data-var deal-counter uint u1)

;; ============================================
;; Data Maps
;; ============================================

;; Payment escrow storage
(define-map payments 
  { id: uint }
  {
    from: principal,
    to: principal,
    amount: uint,
    is-complete: bool,
    created-at: uint
  }
)

;; Deal tracking storage
(define-map deals 
  { deal-id: uint }
  {
    initiator: principal,
    counterparty: principal,
    value: uint,
    state: (string-ascii 20),
    timestamp: uint,
    trust-score: uint
  }
)

;; User reputation profiles
(define-map trust-profiles 
  { address: principal }
  { 
    cumulative-score: uint, 
    deal-count: uint 
  }
)

;; ============================================
;; Private Functions - Validation
;; ============================================

;; Verify counterparty is valid (not self or admin)
(define-private (validate-counterparty (counterparty principal))
  (and 
    (not (is-eq counterparty tx-sender))
    (not (is-eq counterparty ADMIN))
  )
)

;; Verify deal ID exists and is valid
(define-private (validate-deal-id (deal-id uint))
  (and 
    (> deal-id u0)
    (< deal-id (var-get deal-counter))
  )
)

;; Check if user principal is valid
(define-private (is-valid-user (recipient principal))
  (and 
    (not (is-eq recipient tx-sender))
    (not (is-eq recipient ADMIN))
  )
)

;; ============================================
;; Public Functions - Core Protocol
;; ============================================

;; Initialize a new escrowed deal with counterparty
(define-public (initiate-deal 
  (counterparty principal) 
  (value uint)
)
  (begin
    ;; Validate inputs
    (asserts! (is-valid-user counterparty) ERR-INVALID-USER)
    (asserts! (validate-counterparty counterparty) ERR-SELF-DEAL)
    (asserts! (> value u0) ERR-ZERO-AMOUNT)

    (let 
      (
        (id (var-get payment-id-counter))
        (current-deal-id (var-get deal-counter))
      )
      ;; Increment counters
      (var-set payment-id-counter (+ id u1))
      (var-set deal-counter (+ current-deal-id u1))

      ;; Create payment record
      (map-set payments 
        { id: id }
        {
          from: tx-sender,
          to: counterparty,
          amount: value,
          is-complete: false,
          created-at: stacks-block-height
        }
      )
      
      ;; Create deal record
      (map-set deals 
        { deal-id: current-deal-id }
        {
          initiator: tx-sender,
          counterparty: counterparty,
          value: value,
          state: "OPEN",
          timestamp: stacks-block-height,
          trust-score: u0
        }
      )

      (ok current-deal-id)
    )
  )
)

;; Execute payment transfer and mark as complete
(define-public (complete-payment (payment-id uint))
  (let 
    (
      (payment (unwrap! (map-get? payments { id: payment-id }) ERR-NO-PAYMENT))
    )
    ;; Verify caller is payment initiator
    (asserts! (is-eq tx-sender (get from payment)) ERR-NO-AUTH)

    ;; Execute STX transfer
    (try! (stx-transfer? 
      (get amount payment) 
      tx-sender 
      (get to payment)
    ))
    
    ;; Update payment status
    (map-set payments 
      { id: payment-id }
      (merge payment { is-complete: true })
    )
    
    (ok true)
  )
)

;; Submit reputation rating for completed deal
(define-public (rate-counterparty 
  (deal-id uint) 
  (rating uint)
)
  (begin
    ;; Validate deal exists
    (asserts! (validate-deal-id deal-id) ERR-INVALID-DEAL-ID)