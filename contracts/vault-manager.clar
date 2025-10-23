;; (clarity-version 1.1)

;; ==============================================================
;; VAULT MANAGER CONTRACT
;; A secure on-chain vault for STX deposits and withdrawals
;; ==============================================================

;; ---------------------------
;; CONSTANTS & ERROR CODES
;; ---------------------------
(define-constant ERR-INSUFFICIENT u100)
(define-constant ERR-ZERO-AMOUNT u101)
(define-constant ERR-TRANSFER-FAILED u102)

;; ---------------------------
;; DATA MAPS
;; ---------------------------
;; Fixed map syntax - removed extra parentheses
(define-map deposits
  {user: principal}
  {amount: uint})

;; ---------------------------
;; READ-ONLY FUNCTIONS
;; ---------------------------
;; Fixed match expression to use correct variable binding
(define-read-only (get-balance (user principal))
  (match (map-get? deposits {user: user})
    balance (ok (get amount balance))
    (ok u0)))

;; ---------------------------
;; PUBLIC FUNCTIONS
;; ---------------------------

;; deposit:
;; Users can deposit STX into their vault balance.
;; Added amount parameter and proper STX transfer to contract
(define-public (deposit (amount uint))
  (if (<= amount u0)
      (err ERR-ZERO-AMOUNT)
      (let ((current (unwrap! (get-balance tx-sender) (err ERR-TRANSFER-FAILED)))
            (new-balance (+ current amount)))
        ;; Transfer STX from user to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set deposits {user: tx-sender} {amount: new-balance})
        (ok {status: "deposit-success", new-balance: new-balance}))))

;; withdraw:
;; Users can withdraw STX from their stored balance.
;; Fixed transfer direction and unwrap error handling
(define-public (withdraw (amount uint))
  (let ((current (unwrap! (get-balance tx-sender) (err ERR-TRANSFER-FAILED))))
    (if (or (<= amount u0) (< current amount))
        (err ERR-INSUFFICIENT)
        (begin
          ;; Transfer STX from contract to user
          (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
          (map-set deposits {user: tx-sender} {amount: (- current amount)})
          (ok {status: "withdraw-success", remaining: (- current amount)})))))

;; ---------------------------
;; OPTIONAL UTILITY
;; ---------------------------

;; get-total-users:
;; Returns an approximate count of all depositors (not exact, demo only)
;; This is a placeholder for future DAO or analytics integration.
(define-read-only (get-total-users)
  (ok "Tracking of user count can be implemented via event logs or indexing."))
