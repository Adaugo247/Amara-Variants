;; Genetic Variant Repository
;; Improved implementation with expanded data modeling and sharing capabilities

;; Constants and Error Codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-VARIANT-PUBLISHED (err u403))
(define-constant ERR-LIST-FULL (err u429))

;; Data Validation Constants
(define-constant MAX-FREQUENCY-FACTOR u10000)  ;; 100.00% in decimals
(define-constant MAX-EFFECT-RANGE 8000)        ;; Effect score in centimorgans (int)
(define-constant MAX-LIST-SIZE u100)

;; Data Structures
(define-map genetic-variants
    { variant-id: uint }
    {
        researcher: principal,
        details: {
            name: (string-utf8 100),
            chromosome-location: (string-utf8 500),
            mutation-type: (string-utf8 50)
        },
        characteristics: {
            allele-min: uint,
            allele-max: uint,
            effect-score: int,
            penetrance-value: int
        },
        metadata: {
            sequence-hash: (string-ascii 100),
            documented-at: uint
        },
        settings: {
            is-shared: bool,
            variant-published: bool
        }
    }
)

;; Researcher variant tracking
(define-map variants-by-researcher
    { researcher: principal }
    { variant-ids: (list 100 uint) }
)

;; State Variables
(define-data-var variant-counter uint u0)

;; Private Helper Functions

;; Validates characteristic parameters
(define-private (validate-characteristic-params (effect-score int) (penetrance-value int))
    (and 
        (and (>= effect-score (- MAX-EFFECT-RANGE)) (<= effect-score MAX-EFFECT-RANGE))
        (and (>= penetrance-value 0) (<= penetrance-value 100000))
    )
)

;; Validates allele frequency range
(define-private (validate-allele-range (min uint) (max uint))
    (and 
        (>= min u0)
        (>= max min)
        (<= max MAX-FREQUENCY-FACTOR)
    )
)

;; Updates researcher's variant list safely
(define-private (update-researcher-variant-list (researcher principal) (variant-id uint) (is-add bool))
    (let (
        (current-data (default-to { variant-ids: (list) } 
                      (map-get? variants-by-researcher { researcher: researcher })))
        (current-ids (get variant-ids current-data))
    )
        (if is-add
            ;; Adding variant
            (if (>= (len current-ids) u100)
                ERR-LIST-FULL
                (ok (map-set variants-by-researcher
                    { researcher: researcher }
                    { variant-ids: (unwrap! (as-max-len? 
                        (append current-ids variant-id) u100)
                        ERR-LIST-FULL) }
                )))
            ;; Removing variant
            (ok (map-set variants-by-researcher
                { researcher: researcher }
                { variant-ids: (filter not-equal-to-id current-ids variant-id) }
            ))
        )
    )
)

;; Helper for filtering variant IDs
(define-private (not-equal-to-id (list-id uint) (target-id uint)) 
    (not (is-eq list-id target-id))
)

;; Verifies variant ownership
(define-private (is-variant-owner (variant-id uint))
    (match (map-get? genetic-variants { variant-id: variant-id })
        data (is-eq tx-sender (get researcher data))
        false
    )
)

;; Public Functions

;; Registers a new genetic variant discovery
(define-public (register-genetic-variant 
        (name (string-utf8 100))
        (chromosome-location (string-utf8 500))
        (mutation-type (string-utf8 50))
        (allele-min uint)
        (allele-max uint)
        (effect-score int)
        (penetrance-value int)
        (sequence-hash (string-ascii 100))
        (is-shared bool))
    (let (
        (variant-id (+ (var-get variant-counter) u1))
        (current-time (unwrap-panic (get-block-info? time u0)))
    )
        ;; Input validation
        (asserts! (validate-allele-range allele-min allele-max) ERR-INVALID-PARAMS)
        (asserts! (validate-characteristic-params effect-score penetrance-value) ERR-INVALID-PARAMS)
        
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
                    allele-min: allele-min,
                    allele-max: allele-max,
                    effect-score: effect-score,
                    penetrance-value: penetrance-value
                },
                metadata: {
                    sequence-hash: sequence-hash,
                    documented-at: current-time
                },
                settings: {
                    is-shared: is-shared,
                    variant-published: false
                }
            }
        )
        
        ;; Update researcher's variant list
        (try! (update-researcher-variant-list tx-sender variant-id true))
        
        ;; Update counter and return
        (var-set variant-counter variant-id)
        (ok variant-id)
    )
)

;; Updates genetic variant details
(define-public (update-variant-details
        (variant-id uint)
        (name (string-utf8 100))
        (chromosome-location (string-utf8 500))
        (mutation-type (string-utf8 50))
        (is-shared bool))
    (let ((variant (unwrap! (map-get? genetic-variants { variant-id: variant-id }) ERR-NOT-FOUND)))
        (asserts! (is-variant-owner variant-id) ERR-NOT-AUTHORIZED)
        (asserts! (not (get variant-published (get settings variant))) ERR-VARIANT-PUBLISHED)
        
        (map-set genetic-variants
            { variant-id: variant-id }
            (merge variant {
                details: {
                    name: name,
                    chromosome-location: chromosome-location,
                    mutation-type: mutation-type
                },
                settings: (merge (get settings variant) {
                    is-shared: is-shared
                })
            })
        )
        (ok true)
    )
)

;; Publishes genetic variant data (making it immutable)
(define-public (publish-variant-data (variant-id uint))
    (let ((variant (unwrap! (map-get? genetic-variants { variant-id: variant-id }) ERR-NOT-FOUND)))
        (asserts! (is-variant-owner variant-id) ERR-NOT-AUTHORIZED)
        
        (ok (map-set genetic-variants
            { variant-id: variant-id }
            (merge variant {
                settings: (merge (get settings variant) {
                    variant-published: true
                })
            })
        ))
    )
)

;; Read-Only Functions

;; Gets genetic variant information
(define-read-only (get-genetic-variant (variant-id uint))
    (map-get? genetic-variants { variant-id: variant-id })
)

;; Gets all genetic variants cataloged by a researcher
(define-read-only (get-variants-by-researcher (researcher principal))
    (default-to { variant-ids: (list) }
        (map-get? variants-by-researcher { researcher: researcher }))
)

;; Gets total number of registered genetic variants
(define-read-only (get-variant-count)
    (ok (var-get variant-counter))
)

;; Checks if a genetic variant's data is publicly accessible
(define-read-only (is-variant-shared (variant-id uint))
    (match (map-get? genetic-variants { variant-id: variant-id })
        data (ok (get is-shared (get settings data)))
        (err ERR-NOT-FOUND)
    )
)