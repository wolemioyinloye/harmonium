;; Harmonium - Decentralized Music Royalty and Licensing Platform

;; Error Constants
(define-constant ERR_ACCESS_DENIED (err u1000))
(define-constant ERR_ADMIN_ONLY (err u1001))
(define-constant ERR_DUPLICATE_RECORD (err u1002))
(define-constant ERR_RECORD_NOT_FOUND (err u1003))
(define-constant ERR_FUNDS_SHORTAGE (err u1004))
(define-constant ERR_TRACK_NOT_FOUND (err u1005))
(define-constant ERR_LICENSE_EXPIRED (err u1006))
(define-constant ERR_NO_LICENSE (err u1007))
(define-constant ERR_PAYMENT_INVALID (err u1008))
(define-constant ERR_TRACK_UNAVAILABLE (err u1009))
(define-constant ERR_INVALID_ROYALTY (err u1010))
(define-constant ERR_ALREADY_PROCESSED (err u1011))
(define-constant ERR_INVALID_DURATION (err u1012))
(define-constant ERR_LIMIT_REACHED (err u1013))
(define-constant ERR_INVALID_RATE (err u1014))
(define-constant ERR_INVALID_GENRE (err u1015))
(define-constant ERR_INVALID_METADATA (err u1016))

;; Contract Owner
(define-constant PLATFORM_ADMIN tx-sender)

;; Data Variables
(define-data-var royalty-pool-balance uint u0)
(define-data-var total-registered-tracks uint u0)
(define-data-var license-counter uint u0)
(define-data-var platform-paused bool false)

;; Constants
(define-constant BLOCKS_PER_MONTH u4380)
(define-constant MIN_LICENSE_FEE u1000)
(define-constant MAX_LICENSE_COVERAGE u1000000000)
(define-constant MAX_TRACKS_PER_ARTIST u1000)
(define-constant PLATFORM_FEE_PERCENT u5)

;; Principal Maps
(define-map music-artists principal
    {
        verified: bool,
        track-count: uint,
        reputation-score: uint,
        active-status: bool,
        registration-height: uint,
        last-update-height: uint,
        total-earnings: uint
    }
)

(define-map licensees principal
    {
        has-active-license: bool,
        licensed-track-id: uint,
        usage-rights: (string-ascii 64),
        monthly-fee: uint,
        license-start-height: uint,
        license-end-height: uint,
        total-licensed-tracks: uint,
        last-payment-height: uint
    }
)

(define-map music-tracks uint
    {
        artist-address: principal,
        genre: (string-ascii 64),
        license-fee: uint,
        exclusive-rights-price: uint,
        available-for-license: bool,
        active-license-count: uint,
        creation-height: uint,
        min-license-term: uint,
        max-license-term: uint,
        track-metadata: (string-ascii 256)
    }
)

(define-map royalty-payments uint
    {
        licensee-address: principal,
        payment-amount: uint,
        status: (string-ascii 20),
        processing-height: uint,
        usage-report: (string-ascii 256),
        distributor: (optional principal),
        distribution-duration: uint
    }
)

;; Private Functions
(define-private (check-admin-access)
    (is-eq tx-sender PLATFORM_ADMIN)
)

(define-private (validate-license-fee (fee-amount uint))
    (>= fee-amount MIN_LICENSE_FEE)
)

(define-private (validate-rights-price (rights-price uint))
    (and 
        (> rights-price u0)
        (<= rights-price MAX_LICENSE_COVERAGE)
    )
)

(define-private (validate-genre (music-genre (string-ascii 64)))
    (let ((genre-length (len music-genre)))
        (and (> genre-length u0) (<= genre-length u64))
    )
)

(define-private (validate-metadata (track-metadata (string-ascii 256)))
    (let ((metadata-length (len track-metadata)))
        (and (> metadata-length u0) (<= metadata-length u256))
    )
)

(define-private (calculate-platform-fee (payment uint))
    (/ (* payment PLATFORM_FEE_PERCENT) u100)
)

;; Read-Only Functions
(define-read-only (get-artist-info (artist-address principal))
    (map-get? music-artists artist-address)
)

(define-read-only (get-licensee-info (licensee-address principal))
    (map-get? licensees licensee-address)
)

(define-read-only (get-track-info (track-id uint))
    (map-get? music-tracks track-id)
)

(define-read-only (get-royalty-info (payment-id uint))
    (map-get? royalty-payments payment-id)
)

(define-read-only (get-royalty-pool)
    (var-get royalty-pool-balance)
)

(define-read-only (is-platform-paused)
    (var-get platform-paused)
)

;; Public Functions

;; Register as a music artist
(define-public (register-artist)
    (let (
        (existing-artist (map-get? music-artists tx-sender))
        (current-height block-height)
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (is-none existing-artist) ERR_DUPLICATE_RECORD)
    (map-set music-artists tx-sender
        {
            verified: true,
            track-count: u0,
            reputation-score: u100,
            active-status: true,
            registration-height: current-height,
            last-update-height: current-height,
            total-earnings: u0
        }
    )
    (ok true))
)

;; Register a music track
(define-public (register-music-track 
    (music-genre (string-ascii 64)) 
    (licensing-fee uint) 
    (exclusive-price uint)
    (min-term uint)
    (max-term uint)
    (track-metadata (string-ascii 256))
)
    (let (
        (artist-info (unwrap! (map-get? music-artists tx-sender) ERR_RECORD_NOT_FOUND))
        (new-track-id (var-get total-registered-tracks))
        (current-height block-height)
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (get verified artist-info) ERR_ACCESS_DENIED)
    (asserts! (get active-status artist-info) ERR_ACCESS_DENIED)
    (asserts! (< (get track-count artist-info) MAX_TRACKS_PER_ARTIST) ERR_LIMIT_REACHED)
    (asserts! (validate-license-fee licensing-fee) ERR_INVALID_RATE)
    (asserts! (validate-rights-price exclusive-price) ERR_PAYMENT_INVALID)
    (asserts! (>= max-term min-term) ERR_INVALID_DURATION)
    (asserts! (validate-genre music-genre) ERR_INVALID_GENRE)
    (asserts! (validate-metadata track-metadata) ERR_INVALID_METADATA)
    
    (map-set music-tracks new-track-id
        {
            artist-address: tx-sender,
            genre: music-genre,
            license-fee: licensing-fee,
            exclusive-rights-price: exclusive-price,
            available-for-license: true,
            active-license-count: u0,
            creation-height: current-height,
            min-license-term: min-term,
            max-license-term: max-term,
            track-metadata: track-metadata
        }
    )
    
    ;; Update artist's track count
    (map-set music-artists tx-sender
        (merge artist-info { 
            track-count: (+ (get track-count artist-info) u1),
            last-update-height: current-height
        })
    )
    
    (var-set total-registered-tracks (+ new-track-id u1))
    (ok new-track-id))
)

;; Purchase a music license
(define-public (purchase-music-license (track-id uint) (license-term uint) (usage-rights (string-ascii 64)))
    (let (
        (track-info (unwrap! (map-get? music-tracks track-id) ERR_TRACK_NOT_FOUND))
        (artist-info (unwrap! (map-get? music-artists (get artist-address track-info)) ERR_RECORD_NOT_FOUND))
        (current-height block-height)
        (monthly-fee (get license-fee track-info))
        (term-fee (* monthly-fee license-term))
        (platform-fee (calculate-platform-fee term-fee))
        (artist-payment (- term-fee platform-fee))
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (get available-for-license track-info) ERR_TRACK_UNAVAILABLE)
    (asserts! (is-none (map-get? licensees tx-sender)) ERR_DUPLICATE_RECORD)
    (asserts! (and 
        (>= license-term (get min-license-term track-info))
        (<= license-term (get max-license-term track-info))
    ) ERR_INVALID_DURATION)
    
    ;; Process payment
    (try! (stx-transfer? term-fee tx-sender (get artist-address track-info)))
    
    ;; Update royalty pool
    (var-set royalty-pool-balance (+ (var-get royalty-pool-balance) platform-fee))
    
    ;; Register licensee
    (map-set licensees tx-sender
        {
            has-active-license: true,
            licensed-track-id: track-id,
            usage-rights: usage-rights,
            monthly-fee: monthly-fee,
            license-start-height: current-height,
            license-end-height: (+ current-height (* license-term BLOCKS_PER_MONTH)),
            total-licensed-tracks: u1,
            last-payment-height: current-height
        }
    )
    
    ;; Update track license count
    (map-set music-tracks track-id
        (merge track-info { active-license-count: (+ (get active-license-count track-info) u1) })
    )
    
    ;; Update artist earnings
    (map-set music-artists (get artist-address track-info)
        (merge artist-info { 
            total-earnings: (+ (get total-earnings artist-info) artist-payment),
            last-update-height: current-height
        })
    )
    
    (ok true))
)

;; Submit royalty payment report
(define-public (submit-royalty-report (payment-amount uint) (usage-report (string-ascii 256)))
    (let (
        (licensee-info (unwrap! (map-get? licensees tx-sender) ERR_NO_LICENSE))
        (track-info (unwrap! (map-get? music-tracks (get licensed-track-id licensee-info)) ERR_TRACK_NOT_FOUND))
        (new-payment-id (var-get license-counter))
        (current-height block-height)
        (platform-fee (calculate-platform-fee payment-amount))
        (artist-payment (- payment-amount platform-fee))
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (get has-active-license licensee-info) ERR_NO_LICENSE)
    (asserts! (<= current-height (get license-end-height licensee-info)) ERR_LICENSE_EXPIRED)
    (asserts! (validate-metadata usage-report) ERR_INVALID_METADATA)
    
    ;; Process payment
    (try! (stx-transfer? payment-amount tx-sender (get artist-address track-info)))
    
    ;; Update artist earnings
    (let ((artist-info (unwrap! (map-get? music-artists (get artist-address track-info)) ERR_RECORD_NOT_FOUND)))
        (map-set music-artists (get artist-address track-info)
            (merge artist-info { 
                total-earnings: (+ (get total-earnings artist-info) artist-payment),
                last-update-height: current-height
            })
        )
    )
    
    ;; Create new royalty payment record
    (map-set royalty-payments new-payment-id
        {
            licensee-address: tx-sender,
            payment-amount: payment-amount,
            status: "PROCESSED",
            processing-height: current-height,
            usage-report: usage-report,
            distributor: none,
            distribution-duration: u0
        }
    )
    
    ;; Update royalty pool
    (var-set royalty-pool-balance (+ (var-get royalty-pool-balance) platform-fee))
    
    ;; Update payment counter
    (var-set license-counter (+ new-payment-id u1))
    (ok new-payment-id))
)

;; Purchase exclusive rights to a track
(define-public (purchase-exclusive-rights (track-id uint))
    (let (
        (track-info (unwrap! (map-get? music-tracks track-id) ERR_TRACK_NOT_FOUND))
        (artist-info (unwrap! (map-get? music-artists (get artist-address track-info)) ERR_RECORD_NOT_FOUND))
        (exclusive-price (get exclusive-rights-price track-info))
        (platform-fee (calculate-platform-fee exclusive-price))
        (artist-payment (- exclusive-price platform-fee))
        (current-height block-height)
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (get available-for-license track-info) ERR_TRACK_UNAVAILABLE)
    
    ;; Process payment
    (try! (stx-transfer? exclusive-price tx-sender (get artist-address track-info)))
    
    ;; Update royalty pool
    (var-set royalty-pool-balance (+ (var-get royalty-pool-balance) platform-fee))
    
    ;; Update artist earnings
    (map-set music-artists (get artist-address track-info)
        (merge artist-info { 
            total-earnings: (+ (get total-earnings artist-info) artist-payment),
            last-update-height: current-height
        })
    )
    
    ;; Update track availability
    (map-set music-tracks track-id
        (merge track-info { 
            available-for-license: false,
            exclusive-rights-price: u0
        })
    )
    
    (ok true))
)

;; Cancel music license
(define-public (cancel-music-license)
    (let (
        (licensee-info (unwrap! (map-get? licensees tx-sender) ERR_NO_LICENSE))
        (track-info (unwrap! (map-get? music-tracks (get licensed-track-id licensee-info)) ERR_TRACK_NOT_FOUND))
        (remaining-blocks (- (get license-end-height licensee-info) block-height))
        (remaining-months (/ remaining-blocks BLOCKS_PER_MONTH))
        (refund-amount (* remaining-months (get monthly-fee licensee-info)))
        (platform-fee (calculate-platform-fee refund-amount))
        (artist-refund (- refund-amount platform-fee))
    )
    (asserts! (not (var-get platform-paused)) ERR_ACCESS_DENIED)
    (asserts! (get has-active-license licensee-info) ERR_NO_LICENSE)
    
    ;; Process refund
    (try! (stx-transfer? artist-refund (get artist-address track-info) tx-sender))
    
    ;; Update royalty pool balance
    (var-set royalty-pool-balance (- (var-get royalty-pool-balance) platform-fee))
    
    ;; Remove licensee
    (map-delete licensees tx-sender)
    
    ;; Update track license count
    (map-set music-tracks (get licensed-track-id licensee-info)
        (merge track-info { active-license-count: (- (get active-license-count track-info) u1) })
    )
    
    (ok true))
)

;; Platform pause/unpause
(define-public (set-platform-status (new-status bool))
    (begin
        (asserts! (check-admin-access) ERR_ADMIN_ONLY)
        (var-set platform-paused new-status)
        (ok true))
)

;; Emergency shutdown
(define-public (emergency-shutdown)
    (begin
        (asserts! (check-admin-access) ERR_ADMIN_ONLY)
        (var-set platform-paused true)
        (ok true))
)