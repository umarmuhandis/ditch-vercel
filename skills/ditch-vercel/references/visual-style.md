# Visual Style

All user-facing output must use the cyberpunk "Escape Sequence" visual language. Follow these rules when rendering output in every phase:

1. **Major frames** (Phase 1 banner, Phase 5 completion): Use double-line box-drawing characters — `╔` `═` `╗` `║` `╚` `═` `╝`
2. **Reports and sub-panels** (Phase 2 report, Phase 3 plan): Use single-line rounded box-drawing — `┌` `─` `┐` `│` `└` `─` `┘`
3. **Narrative/status lines**: Prefix with `>` — e.g. `> VERCEL LOCK-IN DETECTED`
4. **Progress bars** (Phase 4): `██` for filled segments, `░░` for empty segments
5. **Status tags** (Phase 4 tracker): `CLEAR` (completed), `ACTIVE` (in progress), `QUEUED` (pending), `FAILED` (error), `SKIPPED` (user skipped)
6. **Prefix symbols** used across phases:
   - `[✓]` — done / automated
   - `[!]` — needs attention
   - `[✗]` — blocker / critical
   - `+` — add
   - `-` — remove
   - `~` — modify
   - `×` — delete
   - `◆` — manual action
