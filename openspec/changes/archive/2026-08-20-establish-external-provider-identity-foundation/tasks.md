## 1. Persistence Model

- [x] 1.1 Add the `user_identities` migration with TypeID user ownership, provider allowlist, uniqueness constraints, indexes, and cascading deletion
- [x] 1.2 Add `D20.Accounts.UserIdentity` with minimal fields, validations, constraint mappings, and the `User` association
- [x] 1.3 Derive the `user_id` TypeID prefix from the `User` association instead of duplicating it on `belongs_to`
- [x] 1.4 Give every user identity an `identity`-prefixed TypeID primary key

## 2. Accounts Boundary

- [x] 2.1 Add library-independent Accounts operations to link, list, and resolve external identities
- [x] 2.2 Document the public operation contracts and keep provider payloads and credentials outside the context
- [x] 2.3 Keep external identity lookup strict by removing duplicate provider and UID guards from the read path

## 3. Behavior Coverage

- [x] 3.1 Test supported and unsupported providers, required values, length limits, and the minimal schema surface
- [x] 3.2 Test linking, exact resolution, user-scoped listing, both uniqueness invariants, cross-provider UIDs, and cascading deletion

## 4. Documentation and Validation

- [x] 4.1 Complete and review the source-grounded Ueberauth integration research artifact against the implemented persistence boundary
- [x] 4.2 Format touched files and run targeted Accounts tests
- [x] 4.3 Run the complete backend test suite and strict OpenSpec validation
- [x] 4.4 Re-run focused Accounts tests and strict OpenSpec validation after simplifying the lookup contract
- [x] 4.5 Verify TypeID association inference through focused Accounts tests and strict OpenSpec validation
- [x] 4.6 Verify the `identity` TypeID prefix through focused Accounts tests and strict OpenSpec validation
