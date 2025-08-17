# MediKey - Medical Records Management Smart Contract

A decentralized medical records and patient data management system built on the Stacks blockchain using Clarity smart contracts. MedVault provides secure, transparent, and controlled access to medical records while maintaining patient privacy and data integrity.

## Overview

MediKey enables healthcare providers to create, manage, and share medical records on a blockchain infrastructure. The system implements role-based access controls, data usage tracking, and administrative oversight to ensure compliance with healthcare data management standards.

## Features

- **Decentralized Record Storage**: Medical records stored securely on the blockchain
- **Role-Based Access Control**: Physicians control access to their patients' records
- **Data Usage Tracking**: Monitor how much medical data has been accessed
- **Administrative Oversight**: Chief Medical Officer (CMO) can manage system maintenance
- **Access Privilege Management**: Grant and revoke access permissions for medical staff
- **Record Archival**: Deactivate records while preserving data integrity
- **System Maintenance Mode**: Temporary suspension of operations for updates

## Smart Contract Architecture

### Data Structures

#### Medical Records
Each medical record contains:
- `physician`: The attending physician's principal address
- `record-category`: Descriptive category of the medical record (max 64 characters)
- `data-volume`: Total amount of data in the record
- `accessed-volume`: Amount of data that has been accessed
- `created-at`: Block height when the record was created
- `active-record`: Boolean indicating if the record is active

#### Physician Statistics
Tracks performance metrics for each physician:
- `record-count`: Number of records created by the physician
- `total-data-managed`: Total data volume managed by the physician

#### Access Privileges
Controls who can access specific records:
- `can-access`: Boolean permission flag
- `access-limit`: Maximum data volume the staff member can access

### Key Constants

- `chief-medical-officer`: The contract deployer who has administrative privileges
- Various error codes for different failure scenarios

## Functions

### Read-Only Functions

#### `get-medical-record(record-id)`
Retrieves a medical record by its ID.
```clarity
(get-medical-record u1)
```

#### `get-physician-stats(physician)`
Returns statistics for a specific physician.
```clarity
(get-physician-stats 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `get-total-records()`
Returns the total number of medical records in the system.

#### `is-system-maintenance()`
Checks if the system is currently in maintenance mode.

#### `get-access-privilege(record-id, medical-staff)`
Retrieves access privileges for a specific staff member and record.

#### `is-chief-medical-officer(user)`
Verifies if a user is the Chief Medical Officer.

### Public Functions

#### `create-medical-record(record-category, data-volume)`
Creates a new medical record.

**Parameters:**
- `record-category`: String description of the record type (max 64 chars)
- `data-volume`: Size of the medical data (must be > 0)

**Returns:** Record ID if successful

**Example:**
```clarity
(create-medical-record "Cardiology Consultation" u1000)
```

#### `access-medical-data(record-id, access-volume)`
Accesses medical data from a specific record.

**Parameters:**
- `record-id`: ID of the medical record
- `access-volume`: Amount of data to access

**Access Control:**
- Record physician can always access
- Other staff need explicit privileges
- Cannot exceed total data volume
- Record must be active

#### `grant-medical-access(record-id, medical-staff, access-limit)`
Grants access privileges to medical staff for a specific record.

**Parameters:**
- `record-id`: Target medical record
- `medical-staff`: Principal address of the staff member
- `access-limit`: Maximum data volume they can access

**Authorization:** Only the record's physician can grant access

#### `revoke-medical-access(record-id, medical-staff)`
Removes access privileges from medical staff.

**Authorization:** Only the record's physician can revoke access

#### `archive-record(record-id)`
Deactivates a medical record (sets `active-record` to false).

**Authorization:** Only the record's physician can archive

#### `enable-maintenance()` / `disable-maintenance()`
Controls system maintenance mode.

**Authorization:** Only the Chief Medical Officer can toggle maintenance mode

## Error Codes

- `u100`: CMO-only operation attempted by non-CMO
- `u101`: Medical record not found
- `u102`: Insufficient clearance (trying to access more data than available)
- `u103`: Invalid data size (must be > 0)
- `u104`: Record duplicate
- `u105`: Unauthorized access
- `u106`: System in maintenance mode
- `u107`: Record category too long (> 64 characters)
- `u108`: Record is not active

## Usage Examples

### Creating a Medical Record
```clarity
;; Create a new cardiology record
(contract-call? .medvault create-medical-record "Cardiology - ECG Results" u500)
;; Returns: (ok u1) - record ID 1 created
```

### Granting Access to Medical Staff
```clarity
;; Grant access to a nurse for record 1
(contract-call? .medvault grant-medical-access u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u200)
;; Returns: (ok true)
```

### Accessing Medical Data
```clarity
;; Access 100 units of data from record 1
(contract-call? .medvault access-medical-data u1 u100)
;; Returns: (ok true)
```

### Archiving a Record
```clarity
;; Archive record 1
(contract-call? .medvault archive-record u1)
;; Returns: (ok true)
```

## Security Considerations

1. **Access Control**: The contract implements strict role-based access controls
2. **Data Integrity**: All medical data operations are tracked and auditable
3. **Privacy**: Only authorized personnel can access medical records
4. **Administrative Control**: CMO can halt system operations if needed
5. **Immutable Audit Trail**: All transactions are permanently recorded on blockchain

## Deployment

1. Deploy the contract to the Stacks blockchain
2. The deployer automatically becomes the Chief Medical Officer
3. The system initializes with zero records and maintenance mode disabled

## Development and Testing

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Stacks testnet access

### Testing Framework
Consider implementing comprehensive unit tests covering:
- Record creation and management
- Access control mechanisms
- Error handling scenarios
- Administrative functions
- Edge cases and boundary conditions

## Compliance Considerations

While this smart contract provides technical infrastructure for medical record management, implementers should ensure compliance with relevant healthcare regulations such as:
- HIPAA (Health Insurance Portability and Accountability Act)
- GDPR (General Data Protection Regulation)
- Local healthcare data protection laws

## Contributing

When contributing to this project, please ensure:
1. All functions are properly documented
2. Error handling is comprehensive
3. Access controls are thoroughly tested
4. Code follows Clarity best practices