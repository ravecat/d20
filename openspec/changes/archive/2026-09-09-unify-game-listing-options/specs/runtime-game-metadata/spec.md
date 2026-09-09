## MODIFIED Requirements

### Requirement: Metadata failure is returned
The BGG adapter SHALL return `{:error, reason}` when a requested metadata operation fails. Local Games context callers SHALL retain the empty-metadata behavior defined by game-metadata-fallback rather than changing local existence or launch policy. A successful `fetch_games/1` with no matching item SHALL return an empty attrs list; `fetch_game/1` SHALL return game_not_found for an omitted ID, and local single-detail enrichment SHALL preserve its existing empty-metadata fallback.

#### Scenario: BGG detail request fails
- **WHEN** an HTTP, transport, parse, or task timeout failure prevents detail loading
- **THEN** fetch_games returns the source or task error tuple
- **AND** local context callers preserve their selected games through metadata fallback

#### Scenario: BGG returns no matching item
- **WHEN** a valid singleton fetch_games request returns no matching details
- **THEN** the adapter returns an empty attrs list
- **AND** local detail enrichment uses its not-found metadata fallback without synthesizing display fields


### Requirement: BGG detail fetching accepts one or multiple identities
`BoardGameGeek.fetch_games/1` SHALL accept one supplied ID value or a list and return `{:ok, attrs_list}` on successful fetching. It SHALL normalize collection shape only, return an empty list for empty input without credentials or HTTP, and deduplicate input values through inline `Enum.uniq(ids)` at the batch call. Neither fetch_games nor fetch_game SHALL validate ID type, positivity, syntax, or requested/returned identity equality, or return invalid_bgg_ids. Ordinary query serialization SHALL send the supplied values to BGG without an application-specific serializer. The adapter SHALL return parsed response items in request-batch order and provider item order within each batch without filtering, deduplicating, or reordering those items by input identity. Existing parsed-response identity validation SHALL remain. Local listing and Hot callers SHALL retain their existing membership/order through their own metadata association. Former detail API names SHALL remain removed, and the adapter SHALL remain independent of Games context, persistence, and Metadata schema construction.

#### Scenario: One supplied value is requested
- **WHEN** fetch_games receives one serializable scalar value
- **THEN** it sends that value through the same batch flow as a one-element list and returns a list of parsed provider games

#### Scenario: Duplicate input values are requested
- **WHEN** input values repeat
- **THEN** Enum.uniq deduplicates those values directly at the fetch_batches call without an intermediate ids reassignment
- **AND** no integer/string coercion or ID validation is introduced for deduplication

#### Scenario: Supplied values are not locally validated
- **WHEN** input contains numeric strings, other strings, zero, negative numbers, or another normally serializable scalar
- **THEN** the adapter sends the supplied values using ordinary query serialization without an ID validation branch
- **AND** parsed provider results or source errors determine the result

#### Scenario: Input is empty
- **WHEN** fetch_games receives an empty list
- **THEN** it returns an empty list without requiring credentials or an HTTP request

#### Scenario: Provider order and identities differ from input
- **WHEN** BGG returns games in a different order, repeats a game, or resolves an input to a different valid identity
- **THEN** fetch_games retains those parsed items in provider order within each requested batch
- **AND** it does not filter the response by requested identity or reconstruct input order

#### Scenario: Provider returns no games
- **WHEN** a nonempty request succeeds but the response contains no parsed games
- **THEN** fetch_games returns an empty successful list and fetch_game returns game_not_found


### Requirement: BGG detail requests use bounded parallel batches
The adapter SHALL split unique supplied values into batches of at most 20 and send `/xmlapi2/thing` requests with comma-separated IDs, type boardgame, stats 1, runtime bearer authorization, and XML accept headers. It SHALL run at most two detail requests concurrently per invocation. Requests SHALL retain retry false and the 10-second receive timeout. Tasks SHALL have a 15-second timeout, terminate timed-out work, return task-timeout failures as error tuples instead of exiting the caller, and leave no pending work after operation completion. All batches SHALL succeed for an ok result; any failed batch SHALL return an error without a new partial-success result shape. Task completion order SHALL NOT change request-batch order; item order within each response SHALL be preserved. This bound SHALL NOT claim an application-wide request rate guarantee.

#### Scenario: Thirty-two games are requested
- **WHEN** fetch_games receives 32 unique IDs
- **THEN** it sends two batches of 20 and 12 IDs with at most two requests in flight

#### Scenario: More than two batches are needed
- **WHEN** fetch_games receives more than 40 unique IDs
- **THEN** at most two requests run at any instant while remaining batches wait

#### Scenario: Requests finish out of order
- **WHEN** a later batch completes before an earlier batch
- **THEN** the combined attrs list keeps request-batch order and retains each response's item order

#### Scenario: One batch fails
- **WHEN** any detail batch returns an HTTP, transport, or parse error
- **THEN** fetch_games returns an error instead of successful attrs from other batches
- **AND** no partial-result envelope is introduced

#### Scenario: Task exceeds its timeout
- **WHEN** a detail task exceeds 15 seconds
- **THEN** the task is terminated and the caller receives an error tuple
- **AND** no work from that invocation is left running after completion

### Requirement: BGG Hot fetching selects and enriches a bounded random list
`BoardGameGeek.fetch_hot_games(options \\ [])` SHALL accept only limit, using 32 for missing, nonpositive, or non-integer limits and capping positive limits at 100, and ignoring unknown keys. The normalized limit SHALL always be positive; the with SHALL start with credential loading without a redundant positive-limit check or empty-limit branch. A call SHALL fetch `/xmlapi2/hot?type=boardgame` once using existing runtime bearer credentials and HTTP error semantics. Its parser SHALL require an items root, return invalid_hot_response for a different root, return parse errors for malformed XML, discard invalid or nonpositive IDs, and deduplicate valid identities. It SHALL randomly select at most the normalized limit once, then call fetch_games for those identities. It SHALL NOT infer Hot pagination, fixed size, or full-catalog randomness. Selected membership and order SHALL be retained through missing details using identity-only attrs; the fetch_games call SHALL be part of the common with and any detail-operation failure SHALL propagate its error tuple without an adapter fallback warning or replacement list. Hot discovery failures SHALL remain error tuples.

#### Scenario: Hot has more IDs than the limit
- **WHEN** one Hot response contains more distinct valid IDs than requested
- **THEN** one random subset of the requested size is detailed and returned in selected order

#### Scenario: Hot has fewer IDs than requested
- **WHEN** fewer distinct valid IDs are available
- **THEN** only those available identities are returned without padding or another Hot request

#### Scenario: Hot is empty
- **WHEN** Hot returns an empty items root
- **THEN** fetching succeeds with an empty list and no detail request

#### Scenario: Hot response has the wrong root
- **WHEN** valid XML has a root other than items
- **THEN** fetch_hot_games returns invalid_hot_response without requesting details

#### Scenario: Hot IDs are duplicated or invalid
- **WHEN** Hot contains duplicate, absent, invalid, zero, or negative IDs
- **THEN** only unique positive identities enter selection and detail fetching

#### Scenario: Hot detail enrichment fails
- **WHEN** valid IDs have been selected but fetch_games fails
- **THEN** fetch_hot_games returns the detail-operation error
- **AND** no successful replacement list or adapter fallback warning is produced

#### Scenario: Hot discovery itself fails
- **WHEN** credentials, HTTP, transport, or Hot parsing fail before IDs are selected
- **THEN** the adapter returns the error without inventing a game list



#### Scenario: Provider limit is invalid or nonpositive
- **WHEN** limit is absent, nonpositive, or not an integer
- **THEN** Hot selection uses the default limit 32

#### Scenario: Provider limit is zero
- **WHEN** limit is zero
- **THEN** Hot fetching uses limit 32 and follows the normal credential and HTTP flow

### Requirement: BGG single-game fetching returns one record
`BoardGameGeek.fetch_game/1` SHALL use one implementation path for supplied values through `fetch_games([id])`. It SHALL NOT branch on ID type, validate value syntax or positivity, or return invalid_bgg_ids. Exactly one parsed game SHALL yield an ok map; zero or multiple parsed games SHALL yield game_not_found. The parsed provider record SHALL supply the resolved positive BGG identity without matching it back to the supplied value. Source errors SHALL be preserved. Local single-game enrichment SHALL retain its empty Metadata fallback, and successful fetch_games results SHALL remain lists.

#### Scenario: One requested game exists
- **WHEN** fetch_game receives a positive ID and its details are returned
- **THEN** the result contains one normalized attrs map rather than a list

#### Scenario: The requested game is absent
- **WHEN** no matching details are returned for fetch_game
- **THEN** it returns game_not_found and local detail enrichment retains the local game with empty metadata

#### Scenario: Supplied single-game values are delegated
- **WHEN** fetch_game receives a normally serializable supplied value such as a numeric string, zero, or a negative number
- **THEN** the value reaches BGG through the shared fetching path without application-side ID validation
- **AND** a response without exactly one parsed game yields game_not_found

#### Scenario: Single-game loading fails
- **WHEN** authentication, HTTP, transport, parsing, or timeout fails
- **THEN** fetch_game preserves the existing source error tuple

#### Scenario: String identity uses the shared provider flow
- **WHEN** fetch_game receives any string, including a nonnumeric value or a leading-zero numeric value
- **THEN** that exact string is encoded as the Thing id query parameter without application-side syntax validation
- **AND** the result follows the parsed provider response or source error

#### Scenario: A string request returns multiple games
- **WHEN** a raw string request produces more than one parsed game
- **THEN** fetch_game returns game_not_found instead of choosing an arbitrary game
