# Checklist: Iteration 4.1 cleanup plan (targets, wave timer, swap contract)

- [x] Record plan note for remaining cleanup tasks and open questions.
- [x] Add an explicit interaction config flag for swap and wire it into the resolver/service.
- [x] Update design docs to state swap is disabled by config contract.
- [x] Add unit coverage to ensure `configure_shift_clients` does not override configured targets.
- [x] Align interaction config duplication with headless-safe construction (`get_script().new()`).
