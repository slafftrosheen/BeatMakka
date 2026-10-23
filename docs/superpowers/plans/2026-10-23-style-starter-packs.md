# Ten style starter packs

User scope: one starter kit each from TripHop, Dance, Grunge, Hardtrance, HipHop, Industrial, Pop, Reggae, Techno and Trance archives in Music. User declares them freeware usable as wished and requests repository copies of everything used. Record this as user-supplied rights provenance, not independent publisher verification. No source/license files were present in the archives.

Keep sixteen pads, existing default/discovery IDs, four patterns, six shelf positions, controls and image bindings. Use sixteen non-vocal source selections per style. Preserve selected source bytes under sorted repository paths and trace archive/member hashes. Decode split stereo pairs together, remove DC/silence, derive bounded percussion/tonal slices, fade and normalize conservatively to PCM16 mono 44.1 kHz. Clearly label slices and retain originals. Do not copy unused multi-gigabyte archives into Git.

Architecture: add stable style sample IDs and a pack catalog. Sounds browses one kit at a time; applying all sixteen assignments requires version-bound two-press confirmation and preserves notes, tempo and other slots. Mixed kits survive existing save sanitization. Audio prepares only active assignments plus the three discovery previews, evicting unused banks and rejecting late callbacks, so ten packs do not multiply active voices.

- [x] Build one 16-pad starter kit per supplied style, copy untouched selected sources, record hashes/rights/edits and generate review audio and upload manifests. Verify no clipped derived samples and every used source is in the repo.
- [x] Add explicit failing Studio tests for style catalog/persistence, bounded bank switching and pack replacement safeguards.
- [x] Implement catalog, filtered Sounds browsing, confirmed server pack application and bounded audio preparation without changing legacy music.
- [x] Run Studio source/runtime/UI/cleanup checks and pinned tools, review, commit/push and update relevant issue #7. Hosted permission/playback/listening acceptance stays separate; close only fully verified issues.
