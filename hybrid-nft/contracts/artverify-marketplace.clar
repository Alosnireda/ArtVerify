;; ArtVerify Marketplace Contract
;; Handles listing and sales of verified artwork NFTs

;; Error Codes
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PRICE (err u202))
(define-constant ERR_INVALID_STATE (err u203))

;; Constants
(define-constant PLATFORM_FEE u25) ;; 2.5% platform fee (base 1000)
(define-constant ARTIST_ROYALTY u50) ;; 5% artist royalty (base 1000)

;; Data Variables
(define-data-var platform-wallet principal tx-sender)
(define-data-var last-listing-id uint u0)

;; Data Maps
(define-map listings
    { listing-id: uint }
    {
        token-id: uint,
        seller: principal,
        price: uint,
        is-active: bool
    }
)

;; Read-Only Functions
(define-read-only (get-listing (listing-id uint))
    (map-get? listings { listing-id: listing-id })
)

(define-read-only (get-last-listing-id)
    (ok (var-get last-listing-id))
)

;; Helper Functions
(define-private (calculate-platform-fee (amount uint))
    (/ (* amount PLATFORM_FEE) u1000)
)

(define-private (calculate-artist-royalty (amount uint))
    (/ (* amount ARTIST_ROYALTY) u1000)
)

;; Public Functions

;; Create a new listing
(define-public (create-listing (token-id uint) (price uint))
    (let ((new-listing-id (+ (var-get last-listing-id) u1)))
        ;; Validate price
        (asserts! (> price u0) ERR_INVALID_PRICE)
        
        ;; Create listing
        (map-set listings
            { listing-id: new-listing-id }
            {
                token-id: token-id,
                seller: tx-sender,
                price: price,
                is-active: true
            }
        )
        
        ;; Update last listing ID
        (var-set last-listing-id new-listing-id)
        (ok new-listing-id)
    )
)

;; Complete a sale
(define-public (complete-sale (listing-id uint))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_FOUND)))
        ;; Validate listing
        (asserts! (get is-active listing) ERR_INVALID_STATE)
        
        ;; Calculate fees
        (let (
            (price (get price listing))
            (platform-fee (calculate-platform-fee price))
            (artist-royalty (calculate-artist-royalty price))
            (seller-amount (- price (+ platform-fee artist-royalty)))
        )
            ;; Transfer funds
            (try! (stx-transfer? seller-amount tx-sender (get seller listing)))
            (try! (stx-transfer? platform-fee tx-sender (var-get platform-wallet)))
            
            ;; Update listing status
            (ok (map-set listings
                { listing-id: listing-id }
                (merge listing { is-active: false })
            ))
        )
    )
)

;; Cancel a listing (seller only)
(define-public (cancel-listing (listing-id uint))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_FOUND)))
        ;; Validate caller is seller
        (asserts! (is-eq tx-sender (get seller listing)) ERR_NOT_AUTHORIZED)
        (asserts! (get is-active listing) ERR_INVALID_STATE)
        
        ;; Update listing status
        (ok (map-set listings
            { listing-id: listing-id }
            (merge listing { is-active: false })
        ))
    )
)

;; Initialize contract
(define-public (initialize-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get platform-wallet)) ERR_NOT_AUTHORIZED)
        (ok true)
    )
)