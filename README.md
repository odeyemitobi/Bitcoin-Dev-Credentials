# Bitcoin Dev Credentials

A comprehensive skill tracking system for Bitcoin and Stacks developers built on the Stacks blockchain using Clarity smart contracts.

## Overview

Bitcoin Dev Credentials is a decentralized system that allows developers to track their progress across various Bitcoin and Stacks development competencies. The system is designed to be extensible and community-driven, starting with core skills from educational platforms like LearnWeb3 and expanding to cover the entire Bitcoin development ecosystem.

## Features

### 🎯 Skill Categories
Based on LearnWeb3 Stacks curriculum and industry standards:

1. **Clarity Fundamentals** - Basic Clarity language skills
2. **DeFi Protocols** - Lending, borrowing, flash loans, AMMs
3. **Security & Multisig** - Multi-signature implementations
4. **Oracle Integration** - Price feeds and external data sources
5. **Token Standards** - SIP-010, SIP-009 implementations
6. **Testing & Deployment** - Contract testing and deployment

### 📊 Skill Levels
- **Beginner** (0-25 points)
- **Intermediate** (26-75 points) 
- **Advanced** (76-150 points)
- **Expert** (151+ points)

### 🏆 Point System
- **Self-reported achievements**: 10 points
- **Peer verifications**: +5 bonus points
- **Project deployments**: 25 points (future)
- **Course completions**: 20 points (future)

### 🤝 Peer Verification
- Developers with 50+ reputation can verify others' skills
- Prevents self-verification and duplicate verifications
- Builds community trust and credibility

## Smart Contract Architecture

### Core Data Structures

```clarity
;; Individual skill tracking
developer-skills: {
  developer: principal,
  skill-category: uint
} -> {
  points: uint,
  self-reported-achievements: uint,
  verified-achievements: uint,
  last-updated: uint
}

;; Developer profiles
developer-profiles: {
  developer: principal
} -> {
  total-reputation: uint,
  verification-count: uint,
  join-block: uint,
  is-active: bool
}

;; Peer verification records
peer-verifications: {
  verifier: principal,
  verified-developer: principal,
  skill-category: uint
} -> {
  verification-block: uint,
  points-awarded: uint
}
```

### Key Functions

#### Public Functions
- `initialize-profile()` - Create a new developer profile
- `report-skill-achievement(skill-category, description)` - Self-report achievements
- `verify-peer-skill(developer, skill-category)` - Verify another developer's skill

#### Read-Only Functions
- `get-developer-skill(developer, skill-category)` - Get skill details
- `get-developer-profile(developer)` - Get complete profile
- `get-skill-level-name(level)` - Get level name string
- `get-skill-category-name(category)` - Get category name string

## Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) - Stacks development environment
- [Node.js](https://nodejs.org/) - For running tests

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd bitcoin-dev-credentials
```

2. Install dependencies:
```bash
npm install
```

3. Check contract validity:
```bash
clarinet check
```

4. Run tests:
```bash
npm run test
```

## Usage Examples

### Initialize Your Profile
```clarity
(contract-call? .bitcoin-dev-credentials initialize-profile)
```

### Report a Skill Achievement
```clarity
(contract-call? .bitcoin-dev-credentials 
  report-skill-achievement 
  u1 ;; SKILL_CLARITY_FUNDAMENTALS
  "Completed Clarity basics tutorial")
```

### Verify Another Developer's Skill
```clarity
(contract-call? .bitcoin-dev-credentials 
  verify-peer-skill 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM ;; developer
  u2) ;; SKILL_DEFI_PROTOCOLS
```

### Query Skills
```clarity
(contract-call? .bitcoin-dev-credentials 
  get-developer-skill 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u1)
```

## Future Roadmap

### Phase 1: Foundation ✅
- [x] Core skill tracking system
- [x] Peer verification mechanism
- [x] Basic reputation system
- [x] Comprehensive documentation

### Phase 2: Integration (Planned)
- [ ] GitHub integration for automatic verification
- [ ] Course platform integrations (LearnWeb3, etc.)
- [ ] Project deployment verification
- [ ] Web interface for easy interaction

### Phase 3: Community (Planned)
- [ ] Employer/institution endorsements
- [ ] Skill-based job matching
- [ ] Developer leaderboards
- [ ] Achievement badges and NFTs

### Phase 4: Ecosystem (Planned)
- [ ] Cross-chain skill verification
- [ ] Integration with other Bitcoin L2s
- [ ] Developer DAO governance
- [ ] Bounty and grant matching

## Contributing

We welcome contributions! This project is designed to be community-driven and extensible.

### Areas for Contribution
- Additional skill categories
- Integration with educational platforms
- Web interface development
- Testing and documentation
- Community governance

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by LearnWeb3 Stacks Developer Degree courses
- Built on the Stacks blockchain and Bitcoin ecosystem
- Thanks to the Clarity and Stacks developer community

---

**Built with ❤️ for the Bitcoin developer community**
