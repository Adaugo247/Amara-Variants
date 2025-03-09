# Amara Variants


**A blockchain-powered genetic variant repository for secure, immutable genomic data management**

---

## About Amara Variants

Amara Variants is a decentralized genetic variant repository built on blockchain technology. Named after the Igbo word for "immortal," Amara Variants ensures the permanent preservation and secure sharing of genetic variant discoveries. Our platform enables researchers to document, validate, and publish genetic variant data with immutable provenance tracking.

## Features

- **Secure Variant Registration**: Document genetic variants with comprehensive metadata
- **Ownership Management**: Clear attribution and transfer capabilities for research rights
- **Data Validation**: Built-in validation for allele frequencies, effect scores, and other parameters
- **Immutable Publishing**: Permanent preservation of published genetic discoveries
- **Access Control**: Researcher-controlled sharing settings for variant data
- **Comprehensive Metadata**: Store detailed information about chromosome location, mutation types, and more
- **Blockchain Security**: Leveraging distributed ledger technology for data integrity

## Technical Overview

Amara Variants is implemented as a Clarity smart contract (v2.8) with the following components:

### Data Structures

- **Genetic Variants Map**: Stores comprehensive variant data including researcher attribution, genomic details, characteristics, and metadata
- **Researcher Tracking**: Maps researchers to their cataloged variants

### Key Parameters

- **Allele Frequency**: Tracked with precision up to 10,000 decimal points (0.01%)
- **Effect Scoring**: Measured in centimorgans with a range of ±8000
- **Penetrance Values**: Quantified on a scale of 0-100,000

### Security Features

- **Ownership Verification**: All modification operations require ownership verification
- **Publication Safeguards**: Published variants become immutable to preserve scientific record
- **Parameter Validation**: Comprehensive input validation for all genetic data

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for contract deployment and interaction

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-organization/amara-variants.git
   cd amara-variants