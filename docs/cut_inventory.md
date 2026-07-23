# Detlog cut inventory

## Scope

Inventory covers `prolog/**/*.pl` (implementation), test fixtures, and documentation text.

## Operational implementation cuts

Current result from `detlog_verify_cut_free/0`:

- none found.

## Quoted source cuts (allowed)

- `prolog/detlog_cuts.pl` (`sub_term(!, Body)` and pattern analysis terms)
- `prolog/detlog_modes.pl` (`sub_term(!, Body)`)
- `prolog/detlog_verify.pl` (scanner pattern matching for `!`)

## Source fixture cuts (allowed)

- `test/fixtures/sample_program.pl` (`safe_cut/1`)

## Documentation and requirement text cuts (allowed)

- `README.md`
- `PROGRAM_REQUIREMENTS.md`
- `detlog.txt`
- `detlog2.txt`
- `pr2.txt`
