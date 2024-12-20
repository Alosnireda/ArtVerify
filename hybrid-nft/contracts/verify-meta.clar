;; Error Codes
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_SIGNATURE (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_TOKEN (err u104))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var last-token-id uint u0)

;; Data Maps
(define-map metadata-verification
    { token-id: uint }
    {
        metadata-uri: (string-utf8 256),
        metadata-hash: (buff 32),
        last-verified: uint,
        verification-signature: (buff 65),
        artist: principal,
        is-active: bool
    }
)

(define-map artist-registry
    { artist: principal }
    {
        name: (string-utf8 64),
        is-verified: bool,
        registration-height: uint
    }
)

;; Read-Only Functions

(define-read-only (get-metadata-verification (token-id uint))
    (map-get? metadata-verification { token-id: token-id })
)

(define-read-only (get-artist-details (artist principal))
    (map-get? artist-registry { artist: artist })
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (is-contract-owner (address principal))
    (is-eq address (var-get contract-owner))
)

;; Public Functions

;; Register new artist
(define-public (register-artist (artist-name (string-utf8 64)))
    (let
        ((caller tx-sender))
        (asserts! (is-none (map-get? artist-registry { artist: caller })) ERR_ALREADY_EXISTS)
        (ok (map-set artist-registry
            { artist: caller }
            {
                name: artist-name,
                is-verified: false,
                registration-height: block-height
            }
        ))
    )
)

;; Verify artist (only contract owner)
(define-public (verify-artist (artist principal))
    (let
        ((caller tx-sender))
        (asserts! (is-contract-owner caller) ERR_NOT_AUTHORIZED)
        (asserts! (is-some (map-get? artist-registry { artist: artist })) ERR_NOT_FOUND)
        (ok (map-set artist-registry
            { artist: artist }
            (merge (unwrap-panic (map-get? artist-registry { artist: artist }))
                  { is-verified: true })
        ))
    )
)

;; Mint new artwork NFT with metadata
(define-public (mint-artwork-nft
    (metadata-uri (string-utf8 256))
    (metadata-hash (buff 32))
    (verification-signature (buff 65)))
    (let
        ((caller tx-sender)
         (artist-data (unwrap! (map-get? artist-registry { artist: caller }) ERR_NOT_AUTHORIZED))
         (new-token-id (+ (var-get last-token-id) u1)))
        
        ;; Assert artist is verified
        (asserts! (get is-verified artist-data) ERR_NOT_AUTHORIZED)
        
        ;; Store metadata verification
        (map-set metadata-verification
            { token-id: new-token-id }
            {
                metadata-uri: metadata-uri,
                metadata-hash: metadata-hash,
                last-verified: block-height,
                verification-signature: verification-signature,
                artist: caller,
                is-active: true
            }
        )
        
        ;; Update last token ID
        (var-set last-token-id new-token-id)
        (ok new-token-id)
    )
)

;; Update metadata for existing artwork
(define-public (update-artwork-metadata
    (token-id uint)
    (new-uri (string-utf8 256))
    (new-hash (buff 32))
    (new-signature (buff 65)))
    (let
        ((caller tx-sender)
         (metadata (unwrap! (map-get? metadata-verification { token-id: token-id }) ERR_NOT_FOUND)))
        
        ;; Assert caller is the artist
        (asserts! (is-eq caller (get artist metadata)) ERR_NOT_AUTHORIZED)
        ;; Assert token is active
        (asserts! (get is-active metadata) ERR_INVALID_TOKEN)
        
        ;; Update metadata
        (ok (map-set metadata-verification
            { token-id: token-id }
            {
                metadata-uri: new-uri,
                metadata-hash: new-hash,
                last-verified: block-height,
                verification-signature: new-signature,
                artist: caller,
                is-active: true
            }
        ))
    )
)

;; Deactivate artwork (in case of disputes or other issues)
(define-public (deactivate-artwork (token-id uint))
    (let
        ((caller tx-sender)
         (metadata (unwrap! (map-get? metadata-verification { token-id: token-id }) ERR_NOT_FOUND)))
        
        ;; Assert caller is contract owner or artist
        (asserts! (or
            (is-contract-owner caller)
            (is-eq caller (get artist metadata))
        ) ERR_NOT_AUTHORIZED)
        
        ;; Update metadata with deactivated status
        (ok (map-set metadata-verification
            { token-id: token-id }
            (merge metadata { is-active: false })
        ))
    )
)

;; Transfer contract ownership
(define-public (transfer-contract-ownership (new-owner principal))
    (let
        ((caller tx-sender))
        (asserts! (is-contract-owner caller) ERR_NOT_AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

;; Initialize contract
(define-public (initialize-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        (ok true)
    )
)