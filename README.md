

# sBTC-ActiveRank - Fitness Challenge Smart Contract

## Overview

This smart contract enables a decentralized fitness platform where athletes can register, set workout goals, log workouts, complete challenges, earn badges, and claim rewards. The contract manages athlete profiles, workout challenges, badges, and a global reward pool funded by the platform administrator.

---

## Features

* **User Registration:** Athletes can register to participate.
* **Workout Challenges:** Athletes set fitness goals with deadlines and workout types.
* **Workout Logging:** Track progress towards challenges.
* **Rewards:** Earn token rewards from a global reward pool upon completing challenges.
* **Badges:** Achievements issued when challenges are completed.
* **Platform Administration:** Admin can add rewards and transfer ownership.

---

## Error Codes

| Code                                   | Description                        |
| -------------------------------------- | ---------------------------------- |
| ERR-UNAUTHORIZED-ACCESS (u100)         | Unauthorized action by caller      |
| ERR-DUPLICATE-USER-REGISTRATION (u101) | Athlete already registered         |
| ERR-USER-PROFILE-NOT-FOUND (u102)      | Profile not found for athlete      |
| ERR-INVALID-FITNESS-GOAL (u103)        | Invalid workout target or deadline |
| ERR-INSUFFICIENT-REWARD-BALANCE (u104) | Insufficient tokens in reward pool |
| ERR-INVALID-REWARD-AMOUNT (u105)       | Invalid reward token amount        |
| ERR-INVALID-WORKOUT-UNITS (u106)       | Invalid workout units input        |
| ERR-INVALID-CHALLENGE-ID (u107)        | Invalid challenge identifier       |

---

## Data Structures

* **platform-admin (principal):** Contract administrator address.
* **global-reward-pool (uint):** Tokens available for rewarding athletes.
* **member-count (uint):** Total registered athletes.

### Maps

* **athlete-profiles:** Maps athlete principal to profile data including health score, workout count, rank, last workout timestamp, tokens earned, and ongoing challenges count.
* **workout-challenges:** Maps `{athlete-address, challenge-id}` pairs to workout challenge details like targets, progress, deadlines, rewards, and type.
* **athlete-badges:** Maps athlete principal to a list of earned badge names.

---

## Public Functions

### `register-athlete()`

Registers a new athlete. Rejects duplicates.

### `start-workout-challenge(workout-target, challenge-deadline, workout-type)`

Starts a new workout challenge with the given target units, deadline (block time), and workout type (string). Returns the challenge ID.

### `log-workout(challenge-id, workout-units)`

Logs workout units for a specified challenge, updates progress, health score, rank, and awards badges if challenge is completed.

### `claim-challenge-reward(challenge-id)`

Allows athlete to claim token rewards for completed challenges if enough tokens are in the global reward pool.

### `add-reward-tokens(token-amount)`

Adds tokens to the global reward pool. Restricted to the platform administrator.

### `transfer-platform-control(new-admin)`

Transfers platform administration to a new principal. Restricted to current admin.

---

## Private Functions

* `calculate-challenge-reward(workout-target)`: Calculates token rewards based on target units.
* `calculate-health-points(workout-units)`: Calculates health points earned for workout units.
* `calculate-athlete-rank(total-points)`: Calculates athlete rank based on health score.
* `issue-badge(athlete-address, badge-name)`: Issues achievement badges to athletes.

---

## Read-only Views

* `get-athlete-profile(athlete-address)`: Returns athlete profile data.
* `get-challenge-details(athlete-address, challenge-id)`: Returns details of a specific workout challenge.
* `get-athlete-badges(athlete-address)`: Returns badges earned by an athlete.
* `get-platform-metrics()`: Returns total registered athletes and available rewards.

---

## Usage Notes

* All user actions are identified by `tx-sender`.
* Deadlines are compared against current block time.
* Rewards are only claimable once a challenge is completed.
* Badge lists are capped at 10 badges per athlete.
* Admin controls are secured via principal checks.

---

## Future Improvements

* Support for multiple concurrent challenges per athlete.
* More sophisticated ranking and reward algorithms.
* Integration with token contracts for on-chain token transfers.
* Enhanced badge metadata and categorization.
* Frontend UI for user interaction.

---
