
;; sBTC-ActiveRank

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-DUPLICATE-USER-REGISTRATION (err u101))
(define-constant ERR-USER-PROFILE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-FITNESS-GOAL (err u103))
(define-constant ERR-INSUFFICIENT-REWARD-BALANCE (err u104))
(define-constant ERR-INVALID-REWARD-AMOUNT (err u105))
(define-constant ERR-INVALID-WORKOUT-UNITS (err u106))
(define-constant ERR-INVALID-CHALLENGE-ID (err u107))

;; Data variables
(define-data-var platform-admin principal tx-sender)
(define-data-var global-reward-pool uint u0)
(define-data-var member-count uint u0)

;; Data maps
(define-map athlete-profiles
    principal
    {
        health-score: uint,
        workout-count: uint,
        athlete-rank: uint,
        last-workout-time: uint,
        earned-tokens: uint,
        ongoing-challenge-count: uint
    }
)

(define-map workout-challenges
    {athlete-address: principal, challenge-id: uint}
    {
        workout-target: uint,
        workout-progress: uint,
        challenge-deadline: uint,
        challenge-completed: bool,
        token-reward: uint,
        workout-type: (string-ascii 20)
    }
)

(define-map athlete-badges
    principal
    (list 10 (string-ascii 30))
)

;; Public functions

;; Initialize new user
(define-public (register-athlete)
    (let
        ((athlete-address tx-sender))
        (asserts! (is-none (map-get? athlete-profiles athlete-address)) (err ERR-DUPLICATE-USER-REGISTRATION))
        (map-set athlete-profiles
            athlete-address
            {
                health-score: u0,
                workout-count: u0,
                athlete-rank: u1,
                last-workout-time: (unwrap-panic (get-stacks-block-info? time u0)),
                earned-tokens: u0,
                ongoing-challenge-count: u0
            }
        )
        (var-set member-count (+ (var-get member-count) u1))
        (ok true)
    )
)

;; Set fitness goal
(define-public (start-workout-challenge (workout-target uint) (challenge-deadline uint) (workout-type (string-ascii 20)))
    (let
        ((athlete-address tx-sender)
         (athlete-data (unwrap! (map-get? athlete-profiles athlete-address) ERR-USER-PROFILE-NOT-FOUND))
         (challenge-id (+ (get ongoing-challenge-count athlete-data) u1)))

        (asserts! (> workout-target u0) ERR-INVALID-FITNESS-GOAL)
        (asserts! (> challenge-deadline (unwrap-panic (get-stacks-block-info? time u0))) ERR-INVALID-FITNESS-GOAL)
        (asserts! (<= (len workout-type) u20) ERR-INVALID-FITNESS-GOAL)

        (map-set workout-challenges
            {athlete-address: athlete-address, challenge-id: challenge-id}
            {
                workout-target: workout-target,
                workout-progress: u0,
                challenge-deadline: challenge-deadline,
                challenge-completed: false,
                token-reward: (calculate-challenge-reward workout-target),
                workout-type: workout-type
            }
        )

        (map-set athlete-profiles
            athlete-address
            (merge athlete-data {ongoing-challenge-count: challenge-id})
        )
        (ok challenge-id)
    )
)

;; Log activity and update progress
(define-public (log-workout (challenge-id uint) (workout-units uint))
    (let
        ((athlete-address tx-sender)
         (athlete-data (unwrap! (map-get? athlete-profiles athlete-address) ERR-USER-PROFILE-NOT-FOUND)))

        (asserts! (> workout-units u0) ERR-INVALID-WORKOUT-UNITS)
        (asserts! (<= challenge-id (get ongoing-challenge-count athlete-data)) ERR-INVALID-CHALLENGE-ID)

        (let
            ((challenge-data (unwrap! (map-get? workout-challenges {athlete-address: athlete-address, challenge-id: challenge-id}) ERR-INVALID-CHALLENGE-ID))
             (workout-timestamp (unwrap-panic (get-stacks-block-info? time u0))))

            (asserts! (not (get challenge-completed challenge-data)) ERR-INVALID-FITNESS-GOAL)
            (asserts! (<= workout-timestamp (get challenge-deadline challenge-data)) ERR-INVALID-FITNESS-GOAL)

            (let
                ((new-progress (+ (get workout-progress challenge-data) workout-units))
                 (challenge-achieved (>= new-progress (get workout-target challenge-data)))
                 (health-points (calculate-health-points workout-units))
                 (new-health-score (+ (get health-score athlete-data) health-points)))

                ;; Update challenge progress
                (map-set workout-challenges
                    {athlete-address: athlete-address, challenge-id: challenge-id}
                    (merge challenge-data {
                        workout-progress: new-progress,
                        challenge-completed: challenge-achieved
                    })
                )

                ;; Update athlete profile
                (map-set athlete-profiles
                    athlete-address
                    (merge athlete-data {
                        health-score: new-health-score,
                        workout-count: (+ (get workout-count athlete-data) u1),
                        last-workout-time: workout-timestamp,
                        athlete-rank: (calculate-athlete-rank new-health-score)
                    })
                )

                ;; Award badge if challenge completed
                (if challenge-achieved
                    (issue-badge athlete-address (concat "Mastered " (get workout-type challenge-data)))
                    true
                )

                (ok {
                    new-progress: new-progress,
                    challenge-achieved: challenge-achieved,
                    new-health-score: new-health-score
                })
            )
        )
    )
)
