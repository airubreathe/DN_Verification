;; Decentralized News Verification System
;; Community-driven fact-checking with reputation incentives

;; Define fungible token
(define-fungible-token reputation-token)

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-article-exists (err u101))
(define-constant err-article-not-found (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-insufficient-reputation (err u104))
(define-constant err-already-voted (err u105))
(define-constant err-invalid-score (err u106))

;; Define data variables
(define-data-var article-counter uint u0)
(define-data-var min-reputation-to-verify uint u100)
(define-data-var verification-reward uint u50)
(define-data-var false-penalty uint u100)

;; Define maps
(define-map news-articles
    uint
    {
        submitter: principal,
        headline: (string-utf8 200),
        source-url: (string-utf8 200),
        content-hash: (buff 32),
        submission-block: uint,
        verification-count: uint,
        truth-score: uint, ;; 0-100
        verified: bool,
        final-verdict: (string-utf8 20) ;; "true", "false", "misleading", "unverified"
    }
)

(define-map verifier-reputations
    principal
    {
        reputation-score: uint,
        verifications-submitted: uint,
        accurate-verifications: uint,
        join-block: uint,
        last-activity: uint
    }
)

(define-map article-verifications
    { article-id: uint, verifier: principal }
    {
        verdict: (string-utf8 20),
        evidence-url: (string-utf8 200),
        confidence-score: uint, ;; 0-100
        verification-block: uint
    }
)

(define-map verification-challenges
    { article-id: uint, challenger: principal }
    {
        challenge-reason: (string-utf8 500),
        evidence-hash: (buff 32),
        challenge-block: uint,
        support-count: uint
    }
)

;; Read-only functions
(define-read-only (get-article (article-id uint))
    (map-get? news-articles article-id)
)

(define-read-only (get-verifier-reputation (verifier principal))
    (map-get? verifier-reputations verifier)
)

(define-read-only (get-verification (article-id uint) (verifier principal))
    (map-get? article-verifications { article-id: article-id, verifier: verifier })
)

(define-read-only (get-reputation-balance (account principal))
    (ft-get-balance reputation-token account)
)

;; Public functions
(define-public (register-verifier)
    (begin
        (map-set verifier-reputations tx-sender {
            reputation-score: u100, ;; Starting reputation
            verifications-submitted: u0,
            accurate-verifications: u0,
            join-block: stacks-block-height,
            last-activity: stacks-block-height
        })
        (try! (ft-mint? reputation-token u100 tx-sender))
        (ok true)
    )
)

(define-public (submit-article
    (headline (string-utf8 200))
    (source-url (string-utf8 200))
    (content-hash (buff 32)))
    (let
        (
            (article-id (+ (var-get article-counter) u1))
        )
        (map-set news-articles article-id {
            submitter: tx-sender,
            headline: headline,
            source-url: source-url,
            content-hash: content-hash,
            submission-block: stacks-block-height,
            verification-count: u0,
            truth-score: u0,
            verified: false,
            final-verdict: u"unverified"
        })
        (var-set article-counter article-id)
        (ok article-id)
    )
)

(define-public (verify-article
    (article-id uint)
    (verdict (string-utf8 20))
    (evidence-url (string-utf8 200))
    (confidence-score uint))
    (let
        (
            (article (unwrap! (get-article article-id) err-article-not-found))
            (verifier-info (unwrap! (get-verifier-reputation tx-sender) err-insufficient-reputation))
            (existing-verification (get-verification article-id tx-sender))
        )
        (asserts! (is-none existing-verification) err-already-verified)
        (asserts! (>= (get reputation-score verifier-info) (var-get min-reputation-to-verify)) err-insufficient-reputation)
        (asserts! (<= confidence-score u100) err-invalid-score)
        
        (map-set article-verifications
            { article-id: article-id, verifier: tx-sender }
            {
                verdict: verdict,
                evidence-url: evidence-url,
                confidence-score: confidence-score,
                verification-block: stacks-block-height
            }
        )
        
        (map-set news-articles article-id
            (merge article { verification-count: (+ (get verification-count article) u1) })
        )
        
        (map-set verifier-reputations tx-sender
            (merge verifier-info {
                verifications-submitted: (+ (get verifications-submitted verifier-info) u1),
                last-activity: stacks-block-height
            })
        )
        
        (ok true)
    )
)

(define-public (finalize-article-verdict (article-id uint))
    (let
        (
            (article (unwrap! (get-article article-id) err-article-not-found))
        )
        (asserts! (>= (get verification-count article) u5) err-insufficient-reputation)
        (asserts! (not (get verified article)) err-already-verified)
        
        ;; In a real implementation, this would calculate consensus from all verifications
        ;; For simplicity, we're setting it as verified after 5 verifications
        (map-set news-articles article-id
            (merge article {
                verified: true,
                truth-score: u75, ;; Simplified - would be calculated from verifications
                final-verdict: u"true" ;; Simplified - would be consensus verdict
            })
        )
        
        ;; Reward verifiers who participated
        (ok true)
    )
)

(define-public (challenge-verification
    (article-id uint)
    (challenge-reason (string-utf8 500))
    (evidence-hash (buff 32)))
    (let
        (
            (article (unwrap! (get-article article-id) err-article-not-found))
            (challenger-info (unwrap! (get-verifier-reputation tx-sender) err-insufficient-reputation))
        )
        (asserts! (get verified article) err-article-not-found)
        (asserts! (>= (get reputation-score challenger-info) u200) err-insufficient-reputation)
        
        (map-set verification-challenges
            { article-id: article-id, challenger: tx-sender }
            {
                challenge-reason: challenge-reason,
                evidence-hash: evidence-hash,
                challenge-block: stacks-block-height,
                support-count: u0
            }
        )
        
        (ok true)
    )
)

(define-public (reward-accurate-verifier (verifier principal) (amount uint))
    (let
        (
            (verifier-info (unwrap! (get-verifier-reputation verifier) err-insufficient-reputation))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (try! (ft-mint? reputation-token amount verifier))
        
        (map-set verifier-reputations verifier
            (merge verifier-info {
                reputation-score: (+ (get reputation-score verifier-info) amount),
                accurate-verifications: (+ (get accurate-verifications verifier-info) u1)
            })
        )
        (ok true)
    )
)