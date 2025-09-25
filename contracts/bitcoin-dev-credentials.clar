;; Bitcoin Dev Credentials - Skill Tracking System
;; 
;; This contract implements a comprehensive skill tracking system for Bitcoin and Stacks developers.
;; It's designed to track progress through various development competencies, starting with skills
;; from LearnWeb3 Stacks courses (Multisig, Flash Loans, Lending Protocols) and expandable to
;; cover the entire Bitcoin development ecosystem.
;;
;; The system uses a point-based approach where developers can:
;; 1. Self-report skill achievements
;; 2. Get peer verifications for bonus points
;; 3. Track progress across multiple skill categories
;; 4. Earn credentials at different proficiency levels
;;
;; Future extensions can include:
;; - Integration with GitHub for automatic verification
;; - Course completion tracking from educational platforms
;; - Project deployment verification
;; - Employer/institution endorsements

;; ===========================================
;; CONSTANTS AND ERROR CODES
;; ===========================================

;; Error codes for various failure scenarios
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_SKILL_CATEGORY (err u101))
(define-constant ERR_INVALID_POINTS (err u102))
(define-constant ERR_ALREADY_VERIFIED (err u103))
(define-constant ERR_CANNOT_VERIFY_SELF (err u104))
(define-constant ERR_INSUFFICIENT_REPUTATION (err u105))
(define-constant ERR_SKILL_NOT_FOUND (err u106))

;; Skill level thresholds (points required for each level)
(define-constant BEGINNER_THRESHOLD u0)
(define-constant INTERMEDIATE_THRESHOLD u26)
(define-constant ADVANCED_THRESHOLD u76)
(define-constant EXPERT_THRESHOLD u151)

;; Point values for different types of achievements
(define-constant SELF_REPORT_POINTS u10)
(define-constant PEER_VERIFICATION_BONUS u5)
(define-constant PROJECT_DEPLOYMENT_POINTS u25)
(define-constant COURSE_COMPLETION_POINTS u20)

;; Minimum reputation required to verify others (prevents spam)
(define-constant MIN_VERIFIER_REPUTATION u50)

;; ===========================================
;; SKILL CATEGORIES
;; ===========================================

;; Core skill categories based on LearnWeb3 Stacks curriculum
;; Each category represents a major area of Bitcoin/Stacks development
(define-constant SKILL_CLARITY_FUNDAMENTALS u1)    ;; Basic Clarity language skills
(define-constant SKILL_DEFI_PROTOCOLS u2)          ;; Lending, borrowing, AMMs
(define-constant SKILL_SECURITY_MULTISIG u3)       ;; Multi-signature implementations
(define-constant SKILL_ORACLE_INTEGRATION u4)      ;; Price feeds, external data
(define-constant SKILL_TOKEN_STANDARDS u5)         ;; SIP-010, SIP-009 standards
(define-constant SKILL_TESTING_DEPLOYMENT u6)      ;; Contract testing and deployment

;; ===========================================
;; DATA STRUCTURES
;; ===========================================

;; Individual skill record for a developer in a specific category
(define-map developer-skills
  {
    developer: principal,
    skill-category: uint
  }
  {
    points: uint,                    ;; Total points earned in this skill
    self-reported-achievements: uint, ;; Number of self-reported items
    verified-achievements: uint,      ;; Number of peer-verified items
    last-updated: uint               ;; Block height of last update
  }
)

;; Overall developer profile and reputation
(define-map developer-profiles
  { developer: principal }
  {
    total-reputation: uint,          ;; Sum of all skill points across categories
    verification-count: uint,        ;; Number of verifications given to others
    join-block: uint,               ;; Block when developer first registered
    is-active: bool                 ;; Whether the profile is active
  }
)

;; Peer verification records to prevent duplicate verifications
(define-map peer-verifications
  {
    verifier: principal,
    verified-developer: principal,
    skill-category: uint
  }
  {
    verification-block: uint,        ;; When verification was given
    points-awarded: uint             ;; Points awarded through verification
  }
)

;; ===========================================
;; PRIVATE HELPER FUNCTIONS
;; ===========================================

;; Calculate skill level based on points earned
;; @param points: Total points in a skill category
;; @returns: Skill level (1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert)
(define-private (calculate-skill-level (points uint))
  (if (>= points EXPERT_THRESHOLD)
    u4  ;; Expert
    (if (>= points ADVANCED_THRESHOLD)
      u3  ;; Advanced
      (if (>= points INTERMEDIATE_THRESHOLD)
        u2  ;; Intermediate
        u1  ;; Beginner
      )
    )
  )
)

;; Validate that a skill category is supported
;; @param category: Skill category ID to validate
;; @returns: Boolean indicating if category is valid
(define-private (is-valid-skill-category (category uint))
  (and 
    (>= category u1)
    (<= category u6)
  )
)

;; Get current developer reputation (sum of all skill points)
;; @param developer: Principal of the developer
;; @returns: Total reputation points across all skills
(define-private (get-developer-reputation (developer principal))
  (default-to u0 
    (get total-reputation 
      (map-get? developer-profiles { developer: developer })
    )
  )
)

;; ===========================================
;; PUBLIC FUNCTIONS - PROFILE MANAGEMENT
;; ===========================================

;; Initialize a new developer profile
;; This creates the basic profile structure for tracking skills
;; @returns: Success response
(define-public (initialize-profile)
  (let (
    (existing-profile (map-get? developer-profiles { developer: tx-sender }))
  )
    ;; Only create profile if it doesn't exist
    (if (is-none existing-profile)
      (begin
        (map-set developer-profiles
          { developer: tx-sender }
          {
            total-reputation: u0,
            verification-count: u0,
            join-block: block-height,
            is-active: true
          }
        )
        (ok true)
      )
      (ok true) ;; Profile already exists, that's fine
    )
  )
)

;; ===========================================
;; PUBLIC FUNCTIONS - SKILL TRACKING
;; ===========================================

;; Report a self-achieved skill milestone
;; Developers can self-report achievements like completing tutorials,
;; building projects, or learning new concepts
;; @param skill-category: Which skill area this achievement relates to
;; @param description: Brief description of the achievement (for future use)
;; @returns: Success response with points awarded
(define-public (report-skill-achievement (skill-category uint) (description (string-ascii 256)))
  (let (
    (current-skill (default-to 
      { points: u0, self-reported-achievements: u0, verified-achievements: u0, last-updated: u0 }
      (map-get? developer-skills { developer: tx-sender, skill-category: skill-category })
    ))
    (current-profile (map-get? developer-profiles { developer: tx-sender }))
    (new-points (+ (get points current-skill) SELF_REPORT_POINTS))
    (new-achievements (+ (get self-reported-achievements current-skill) u1))
  )
    ;; Validate inputs
    (asserts! (is-valid-skill-category skill-category) ERR_INVALID_SKILL_CATEGORY)
    (asserts! (is-some current-profile) ERR_NOT_AUTHORIZED)
    
    ;; Update skill record
    (map-set developer-skills
      { developer: tx-sender, skill-category: skill-category }
      {
        points: new-points,
        self-reported-achievements: new-achievements,
        verified-achievements: (get verified-achievements current-skill),
        last-updated: block-height
      }
    )
    
    ;; Update total reputation in profile
    (map-set developer-profiles
      { developer: tx-sender }
      (merge (unwrap-panic current-profile)
        { total-reputation: (+ (get total-reputation (unwrap-panic current-profile)) SELF_REPORT_POINTS) }
      )
    )
    
    (ok SELF_REPORT_POINTS)
  )
)

;; Verify another developer's skill achievement
;; This allows peer verification to add credibility to self-reported skills
;; Verifiers must have sufficient reputation to prevent spam
;; @param developer: Principal of developer being verified
;; @param skill-category: Skill category being verified
;; @returns: Success response with bonus points awarded
(define-public (verify-peer-skill (developer principal) (skill-category uint))
  (let (
    (verifier-reputation (get-developer-reputation tx-sender))
    (existing-verification (map-get? peer-verifications
      { verifier: tx-sender, verified-developer: developer, skill-category: skill-category }))
    (current-skill (map-get? developer-skills { developer: developer, skill-category: skill-category }))
    (current-profile (map-get? developer-profiles { developer: developer }))
    (verifier-profile (map-get? developer-profiles { developer: tx-sender }))
  )
    ;; Validation checks
    (asserts! (is-valid-skill-category skill-category) ERR_INVALID_SKILL_CATEGORY)
    (asserts! (not (is-eq tx-sender developer)) ERR_CANNOT_VERIFY_SELF)
    (asserts! (>= verifier-reputation MIN_VERIFIER_REPUTATION) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (is-none existing-verification) ERR_ALREADY_VERIFIED)
    (asserts! (is-some current-skill) ERR_SKILL_NOT_FOUND)
    (asserts! (is-some current-profile) ERR_NOT_AUTHORIZED)
    (asserts! (is-some verifier-profile) ERR_NOT_AUTHORIZED)

    ;; Record the verification
    (map-set peer-verifications
      { verifier: tx-sender, verified-developer: developer, skill-category: skill-category }
      {
        verification-block: block-height,
        points-awarded: PEER_VERIFICATION_BONUS
      }
    )

    ;; Update verified developer's skill points
    (map-set developer-skills
      { developer: developer, skill-category: skill-category }
      (merge (unwrap-panic current-skill)
        {
          points: (+ (get points (unwrap-panic current-skill)) PEER_VERIFICATION_BONUS),
          verified-achievements: (+ (get verified-achievements (unwrap-panic current-skill)) u1),
          last-updated: block-height
        }
      )
    )

    ;; Update verified developer's total reputation
    (map-set developer-profiles
      { developer: developer }
      (merge (unwrap-panic current-profile)
        { total-reputation: (+ (get total-reputation (unwrap-panic current-profile)) PEER_VERIFICATION_BONUS) }
      )
    )

    ;; Update verifier's verification count
    (map-set developer-profiles
      { developer: tx-sender }
      (merge (unwrap-panic verifier-profile)
        { verification-count: (+ (get verification-count (unwrap-panic verifier-profile)) u1) }
      )
    )

    (ok PEER_VERIFICATION_BONUS)
  )
)

;; ===========================================
;; READ-ONLY FUNCTIONS - DATA QUERIES
;; ===========================================

;; Get developer's skill information for a specific category
;; @param developer: Principal of the developer
;; @param skill-category: Skill category to query
;; @returns: Optional skill record with points, achievements, and level
(define-read-only (get-developer-skill (developer principal) (skill-category uint))
  (let (
    (skill-data (map-get? developer-skills { developer: developer, skill-category: skill-category }))
  )
    (match skill-data
      skill-record (some {
        points: (get points skill-record),
        level: (calculate-skill-level (get points skill-record)),
        self-reported-achievements: (get self-reported-achievements skill-record),
        verified-achievements: (get verified-achievements skill-record),
        last-updated: (get last-updated skill-record)
      })
      none
    )
  )
)

;; Get developer's complete profile information
;; @param developer: Principal of the developer
;; @returns: Optional profile with reputation, verification count, and status
(define-read-only (get-developer-profile (developer principal))
  (map-get? developer-profiles { developer: developer })
)

;; Get skill level name as string for display purposes
;; @param level: Numeric skill level (1-4)
;; @returns: String representation of the skill level
(define-read-only (get-skill-level-name (level uint))
  (if (is-eq level u4)
    "Expert"
    (if (is-eq level u3)
      "Advanced"
      (if (is-eq level u2)
        "Intermediate"
        "Beginner"
      )
    )
  )
)

;; Get skill category name for display purposes
;; @param category: Numeric skill category (1-6)
;; @returns: String representation of the skill category
(define-read-only (get-skill-category-name (category uint))
  (if (is-eq category SKILL_CLARITY_FUNDAMENTALS)
    "Clarity Fundamentals"
    (if (is-eq category SKILL_DEFI_PROTOCOLS)
      "DeFi Protocols"
      (if (is-eq category SKILL_SECURITY_MULTISIG)
        "Security & Multisig"
        (if (is-eq category SKILL_ORACLE_INTEGRATION)
          "Oracle Integration"
          (if (is-eq category SKILL_TOKEN_STANDARDS)
            "Token Standards"
            (if (is-eq category SKILL_TESTING_DEPLOYMENT)
              "Testing & Deployment"
              "Unknown Category"
            )
          )
        )
      )
    )
  )
)

;; Check if a peer verification exists
;; @param verifier: Principal who gave the verification
;; @param developer: Principal who received the verification
;; @param skill-category: Skill category that was verified
;; @returns: Optional verification record
(define-read-only (get-peer-verification (verifier principal) (developer principal) (skill-category uint))
  (map-get? peer-verifications
    { verifier: verifier, verified-developer: developer, skill-category: skill-category }
  )
)
