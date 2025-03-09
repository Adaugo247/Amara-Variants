;; Genetic Variant Repository
;; Version: 1.0
;; Basic implementation for genetic variant tracking

;; Constants and Error Codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))

;; Data Validation Constants
(define-constant MAX-FREQUENCY-FACTOR u10000)  ;; 100.00% in decimals
(define-constant MAX-EFFECT-RANGE 5000)        ;; Effect score in centimorgans (int)

;; Data Structures
(define-map genetic-variants
    { variant-id: uint }
    {
        researcher: principal,
        details: {
            name: (string-utf8 100),
            chromosome-location: (string-utf8 100),
            mutation-type: (string-utf8 50)
        },
        characteristics: {
            allele-frequency: uint,
            effect-score: int
        },
        metadata: {
            sequence-hash: (string-ascii 100),
            documented-at: uint
        }
    }
)

;; State Variables
(define-data-var variant-counter uint u0)

;; Private Helper Functions

;; Validates basic parameters
(define-private (validate-params (allele-frequency uint) (effect-score int))
    (and 
        (<= allele-frequency MAX-FREQUENCY-FACTOR)
        (and (>= effect-score (- MAX-EFFECT-RANGE)) (<= effect-score MAX-EFFECT-RANGE))
    )
)

;; Verifies variant ownership
(define-private (is-variant-owner (variant-id uint))
    (match (map-get? genetic-variants { variant-id: variant-id })
        data (is-eq tx-sender (get researcher data))
        false
    )
)

;; Public Functions

;; Registers a new genetic variant
(define-public (register-genetic-variant 
        (name (string-utf8 100))
        (chromosome-location (string-utf8 100))
        (mutation-type (string-utf8 50))
        (allele-frequency uint)
        (effect-score int)
        (sequence-hash (string-ascii 100)))
    (let (
        (variant-id (+ (var-get variant-counter) u1))
        (current-time (unwrap-panic (get-block-info? time u0)))
    )
        ;; Input validation
        (asserts! (validate-params allele-frequency effect-score) ERR-INVALID-PARAMS)
        
        ;; Create genetic variant record
        (map-set genetic-variants
            { variant-id: variant-id }
            {
                researcher: tx-sender,
                details: {
                    name: name,
                    chromosome-location: chromosome-location,
                    mutation-type: mutation-type
                },
                characteristics: {
                    allele-frequency: allele-frequency,
                    effect-score: effect-score
                },
                metadata: {
                    sequence-hash: sequence-hash,
                    documented-at: current-time
                }
            }
        )
        
        ;; Update counter and return
        (var-set variant-counter variant-id)
        (ok variant-id)
    )
)

;; Updates genetic variant details
(define-public (update-variant-details
        (variant-id uint)
        (name (string-utf8 100))
        (chromosome-location (string-utf8 100))
        (mutation-type (string-utf8 50)))
    (let ((variant (unwrap! (map-get? genetic-variants { variant-id: variant-id }) ERR-NOT-FOUND)))
        (asserts! (is-variant-owner variant-id) ERR-NOT-AUTHORIZED)
        
        (map-set genetic-variants
            { variant-id: variant-id }
            (merge variant {
                details: {
                    name: name,
                    chromosome-location: chromosome-location,
                    mutation-type: mutation-type
                }
            })
        )
        (ok true)
    )
)

;; Read-Only Functions

;; Gets genetic variant information
(define-read-only (get-genetic-variant (variant-id uint))
    (map-get? genetic-variants { variant-id: variant-id })
)

;; Gets total number of registered genetic variants
(define-read-only (get-variant-count)
    (ok (var-get variant-counter))
)