# Harmonium

A decentralized music royalty and licensing platform built on the Stacks blockchain with Clarity smart contracts.

## Overview

Harmonium revolutionizes the music industry by creating a transparent, efficient, and trustless ecosystem for music licensing and royalty distribution. The platform enables direct artist-to-licensee relationships, eliminating intermediaries and ensuring creators receive fair compensation for their work.

## Problems Solved

- **Royalty Transparency**: Traditional music industry suffers from opaque royalty calculations and payment processes
- **Middleman Fees**: Multiple intermediaries reduce artists' earnings
- **Payment Delays**: Artists often wait months or years to receive royalty payments
- **Usage Tracking**: Limited visibility into where and how music is being used commercially
- **Licensing Complexity**: Complicated licensing processes create barriers for both artists and licensees

## Key Features

- **Direct Artist Registration**: Musicians can register and maintain full control of their catalog
- **Flexible Licensing Options**: Create customized licensing terms for different usage scenarios
- **Automated Royalty Distribution**: Smart contract-powered instant royalty payments
- **Usage Reporting**: Transparent reporting of music usage through the blockchain
- **Exclusive Rights Transfer**: Option to sell exclusive rights to tracks
- **Reputation System**: Quality scores for artists based on licensing history

## Technical Components

### Smart Contract Maps
- `music-artists`: Registry of verified music creators and their statistics
- `licensees`: Tracks all active music licenses and usage rights
- `music-tracks`: Catalog of registered music with licensing terms
- `royalty-payments`: Records of all royalty transactions and usage reports

### Core Functions

#### For Artists
- `register-artist`: Join the platform as a verified musician
- `register-music-track`: Add a new track to the licensing catalog
- `set-track-status`: Update track availability and licensing terms

#### For Licensees
- `purchase-music-license`: Obtain rights to use music under specific terms
- `submit-royalty-report`: Report usage and make additional royalty payments
- `purchase-exclusive-rights`: Buy exclusive ownership of a track
- `cancel-music-license`: Terminate a license with proportional refund

#### Platform Administration
- `set-platform-status`: Enable or disable platform operations
- `emergency-shutdown`: Trigger system-wide pause in case of emergencies

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- Knowledge of Stacks blockchain concepts
- Understanding of music licensing basics

### Installation

1. Clone the repository
   ```
   git clone https://github.com/wolemioyinloye/harmonium.git
   cd harmonium
   ```

2. Install dependencies
   ```
   npm install
   ```

3. Test the smart contract
   ```
   clarinet test
   ```

## Local Development

### Run Local Devnet
```bash
clarinet integrate
```

### Deploy Contract
```bash
clarinet deploy --network devnet
```

## Smart Contract Architecture

```
Music Artist Registration
        ↓
    Track Registration
        ↓
License Acquisition ← → Royalty Payment
        ↓               ↑
    Usage Reporting → → ↑
        ↓
License Termination/Renewal
```

## Use Cases

1. **Independent Musicians**: Monetize back catalog without label overhead
2. **Content Creators**: Streamline music licensing for videos and podcasts
3. **Advertisers**: Quickly secure commercial music rights
4. **Music Supervisors**: Find and license tracks for films and TV
5. **NFT Creators**: Enable music licensing for digital art and collectibles

## Roadmap

- **Q2 2025**: Support for collaborative splits between multiple artists
- **Q3 2025**: Integration with music streaming services
- **Q4 2025**: Smart contract for merchandise licensing with the same system
- **Q1 2026**: DAO governance for platform parameters and fees

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The Stacks community
- Independent artists who provided feedback
- Web3 music pioneers