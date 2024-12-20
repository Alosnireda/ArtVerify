# ArtVerify: Hybrid NFT Metadata Storage System

ArtVerify is a Clarity smart contract that implements a hybrid approach to NFT metadata storage and verification. The system combines off-chain storage efficiency with on-chain verification security, making it ideal for digital art NFTs with large metadata requirements.

## Features

- **Hybrid Storage System**
  - Store comprehensive metadata off-chain (IPFS/Arweave)
  - Maintain critical verification data on-chain
  - Secure metadata integrity through hash verification

- **Artist Management**
  - Artist registration system
  - Verification process for artists
  - Managed by contract owner
  - Artist profile tracking

- **Artwork Management**
  - Mint new artworks with verified metadata
  - Update metadata with validation checks
  - Deactivate artworks when needed
  - Track artwork status and history

- **Security Features**
  - Input validation for all operations
  - Signature verification
  - Role-based access control
  - Ownership management

## Contract Functions

### Administrative Functions
- `initialize-contract`: Initialize the contract settings
- `transfer-contract-ownership`: Transfer contract ownership to a new address
- `verify-artist`: Verify an artist's registration (contract owner only)

### Artist Functions
- `register-artist`: Register as a new artist
- `get-artist-details`: Retrieve artist information

### Artwork Functions
- `mint-artwork-nft`: Create new artwork with metadata
- `update-artwork-metadata`: Update existing artwork metadata
- `deactivate-artwork`: Deactivate an artwork (owner or artist)
- `get-metadata-verification`: Get artwork metadata details

## Error Codes

- `ERR_NOT_AUTHORIZED (u100)`: Unauthorized access attempt
- `ERR_NOT_FOUND (u101)`: Requested data not found
- `ERR_INVALID_SIGNATURE (u102)`: Invalid signature provided
- `ERR_ALREADY_EXISTS (u103)`: Resource already exists
- `ERR_INVALID_TOKEN (u104)`: Invalid token operation
- `ERR_INVALID_INPUT (u105)`: Invalid input parameters

## Usage Example

1. Deploy the contract
2. Initialize the contract
3. Artists register using `register-artist`
4. Contract owner verifies artists using `verify-artist`
5. Verified artists can mint artwork using `mint-artwork-nft`
6. Artists can update metadata using `update-artwork-metadata`

```clarity
;; Example: Register as an artist
(contract-call? .artverify-metadata-v1 register-artist "Artist Name")

;; Example: Mint new artwork
(contract-call? .artverify-metadata-v1 mint-artwork-nft 
    "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG" 
    0x4f54624b32466d4d7a7777696447556834596f31594a445971446f4e437a4d71 
    0x...)
```

## Security Considerations

- All input data is validated before processing
- Signature verification ensures metadata authenticity
- Role-based access control prevents unauthorized operations
- Token ID validation prevents invalid token operations

## Development Setup

1. Install [Clarinet](https://github.com/hirosystems/clarinet)
2. Clone the repository
3. Run tests: `clarinet test`
4. Deploy using your preferred deployment method