# Decentralized News Verification System

This Clarity smart contract implements a decentralized, community-driven news verification platform. Verifiers earn and spend reputation tokens to assess the truthfulness of news articles, with mechanisms for dispute, consensus, and reward.

## Features

* **Reputation System**: Reputation is tokenized and required for verifying articles.
* **News Submission**: Anyone can submit an article with metadata and content hash.
* **Verifier Registration**: Users register to gain verifier status and initial reputation tokens.
* **Community Verification**: Registered verifiers assess articles, submit verdicts, and provide evidence.
* **Final Verdict**: Consensus is reached after a threshold of verifications (≥5), marking the article as verified.
* **Challenges**: High-reputation users can challenge finalized articles with evidence.
* **Reward System**: Accurate verifiers can be rewarded with additional tokens by the contract owner.

## Token

* **`reputation-token`**: Fungible token used for tracking verifier credibility and incentivizing accurate fact-checking.

## Data Structures

* **`news-articles`**: Stores each submitted article and its verification status.
* **`verifier-reputations`**: Tracks reputation and verification history of users.
* **`article-verifications`**: Records individual verifier contributions.
* **`verification-challenges`**: Manages challenges submitted against verified articles.

## Key Variables

* `article-counter`: Unique article ID generator.
* `min-reputation-to-verify`: Minimum score required to verify.
* `verification-reward`: Reputation gain per verification (future use).
* `false-penalty`: Deduction for incorrect verifications (future use).

## Public Functions

* `register-verifier`: Join the system and receive initial reputation tokens.
* `submit-article`: Add a new news item for review.
* `verify-article`: Submit a verification vote with verdict, evidence, and confidence score.
* `finalize-article-verdict`: Mark an article as verified once threshold is met.
* `challenge-verification`: High-reputation users can dispute verified articles.
* `reward-accurate-verifier`: Admin rewards accurate contributors with reputation tokens.

## Read-Only Functions

* `get-article`
* `get-verifier-reputation`
* `get-verification`
* `get-reputation-balance`

## Governance and Integrity

* Admin has limited powers (e.g., adding rewards).
* Community-driven scoring and consensus.
* Transparent, on-chain record of verdicts and challenges.
