## ADDED Requirements

### Requirement: Automatic completed-turn transitions use lens-based aggregate mutation
After a Koala turn is complete, the aggregate SHALL read its current turn and update final or next-turn state through Pathex field and collection paths. Automatic completion SHALL NOT delegate player status mutation to a map-rebuild helper, and all score and round derivation SHALL retain the existing rules.

#### Scenario: A non-final completed turn advances
- **WHEN** every accepted player has completed a turn that is not final
- **THEN** the aggregate derives the next turn and round from the current turn
- **AND** field lenses set phase to `:roll`, store the next round and turn, and clear the shared roll
- **AND** a collection lens sets every accepted player status to `:ready`
- **AND** all other aggregate and player facts remain unchanged

#### Scenario: The final completed turn finishes the game
- **WHEN** every accepted player has completed the final turn
- **THEN** the aggregate derives scores from the complete post-turn state using the existing scoring rules
- **AND** field lenses set phase to `:finished` and store the derived scores
- **AND** no next-turn reset is applied
- **AND** the existing caller-specific score and rank results remain unchanged
