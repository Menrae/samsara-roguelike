extends Node
## The only cross-system communication channel. Systems talk through these signals;
## do not add direct cross-system references. See docs/ARCHITECTURE.md.

# Item/enemy params are untyped until M4/M5 — Item and Enemy classes don't exist yet.
signal stats_permuted(old_assignment: Dictionary, new_assignment: Dictionary)
signal item_acquired(item)
signal item_activated(item)
signal item_deactivated(item)
signal rift_entered(color: String, realm: String)
signal karma_shifted(delta: float, source: String)
signal enemy_killed(enemy, realm: String)
signal player_died(cause: String)
