# Claude Code Working Rules

## Before doing anything
0. The full design spec is docs/PROJECT_PLAN.md. Read the section for the
   CURRENT milestone before starting. It is the source of truth for design
   decisions; docs/ARCHITECTURE.md describes only how the code is actually
   wired.
1. Read docs/STATE.md. Work ONLY on the milestone listed as CURRENT.
2. Read docs/ARCHITECTURE.md if touching more than one system.

## Hard rules
- NEVER create, edit, or delete anything under assets/. Read paths only.
- Files listed under LOCKED in docs/STATE.md are working code.
  Do not rewrite them. Propose a diff and rationale, then wait.
- New content (item, enemy, realm) = a NEW file in data/. Never edit a system to add content.
- Systems communicate through EventBus signals. Do not add direct
  cross-system references.
- One milestone per session. Do not implement future milestones "while you're here."

## Before finishing
- Update docs/STATE.md: what changed, what's newly LOCKED, next task.
- Append any design decision made under duress to docs/DECISIONS.md.
- Never mark a milestone complete without the "Done when" criteria observably passing in-game.
