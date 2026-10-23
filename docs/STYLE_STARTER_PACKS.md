# Ten style starter kits

23 October 2026. User-requested addition: one kit from each supplied style archive, one coherent key per kit, and repository copies of everything used. The user states the collections are freeware usable as wished. No publisher license/readme was present; the manifest records that user declaration without claiming independent verification.

| Kit | Key | BPM guide | Pads |
| --- | --- | ---: | ---: |
| Trip Hop | A minor | 90 | 16 |
| Dance | A minor | 140 | 16 |
| Grunge | D minor | 90 | 16 |
| Hard Trance | A minor | 140 | 16 |
| Hip Hop | A minor | 90 | 16 |
| Industrial | A minor | 140 | 16 |
| Pop | D major | 90 | 16 |
| Reggae | A minor | 90 | 16 |
| Techno | A minor | 140 | 16 |
| Trance | A minor | 140 | 16 |

Minor kits use root/minor-third/fifth/minor-seventh notes; Pop uses root/major-third/fifth/major-seventh. Note names are shown on tonal pad labels. The BPM guide is used for listening examples; selecting a kit keeps the player's tempo.

## Stored sources and processing

[The source manifest](../assets/candidates/audio/style-starters-v1/manifest.json) records ten archive hashes, every selected archive member, the untouched source file copy, derived file/hash, trim/fades/gain, key and target note. The package contains **195 original source copies and 160 derived pad sounds**. Split stereo pairs are retained as two originals and combined before processing. Paths are sorted by style and pad/role. Unused archive contents are not copied into Git.

All derivatives are mono PCM16 44.1 kHz. Percussion retains source attacks; loop-derived percussion is explicitly labelled as a cut. Voices were excluded from selection. Tonal and FX derivatives use the source's harmonic magnitudes and coarse amplitude envelope projected onto one named key-compatible note. This is additive resynthesis, not a faithful raw-sample pitch shift: original phase, noise and evolving timbre are not preserved. Original sources remain available for further sound design. Musical recognition/genre quality still needs listening review.

The offline verifier checks the complete file roster, source and derived hashes, nonempty PCM format, zero derived clipping, authored key and note labels, and actual fundamental peaks from a zero-padded windowed FFT. All 82 tonal/FX derivatives passed a 10-cent check; maximum observed error was approximately 0.091 cents. This measures rendered digital files, not Roblox or acoustic latency. All 195 repository copies matched the extracted originals, and all ten archive hashes were rechecked. [Receipt](evidence/style-starters/source-and-tuning.json).

## In-game behavior

Sounds browses the original collection or one of ten kits using Previous/Next. The selected kit's key is visible. Individual sounds can be assigned normally. “Use kit on 16 pads” requires a second press within five seconds, bound to the reviewed edit version and station. Browse/navigation/edits/saving/station loss/expiry cancel it. The server validates all sixteen assignments before replacing them atomically, preserving notes, mute flags, tempo and other slots. Original default/discovery IDs and existing save schemas remain intact; mixed assignments still round-trip.

Audio prepares only current pad assignments plus the three original discovery previews: at most nineteen music banks, with four voices per configured bank. UI cues and ambience retain their existing separate banks. Switching kits evicts unused sounds/connections and ignores late callbacks from disposed banks, including when an ID is selected again. It does not allocate every style at launch or allocate voices on a pad hit.

## Listening and upload stage

[The listening page](../output/style-starter-auditions/index.html) has one complete-kit WAV per style and individual pad controls. Each complete review plays the sixteen pads in order, then a two-bar arrangement at the kit's guide tempo. Review attenuation is separate from source gain. All review mixes have zero clipped samples. No desktop/browser was opened or audio played automatically.

The canonical mapping now contains 100 real style audio IDs; 60 remain unconfigured. [The explicit style upload manifest](../data/style-upload-manifest.json) includes all 160 new keys while retaining the 24 original audio keys and fourteen image entries. `python tools/configure_content.py receipt-mapping.json --write` validates both original and style rosters, merges real receipts without discarding existing bindings and rejects accidental rebinding. Regenerating the upload manifest preserves canonical IDs. Existing private-test/no-charge constraints still apply.

## Studio verification

[Receipts](evidence/style-starters/) distinguish source tests from runtime acceptance. Catalog tests cover all 160 new IDs and save sanitization. UI checks cover sixteen visible samples, key labels, two-press replacement and stale/browse/navigation cancellation. Actual Client-to-Server testing applies all eleven kits (original plus ten styles), rejects eleven stale requests, retains notes/tempo and restores the last kit from a local-session save. Audio fixtures verify the nineteen-bank bound, eviction/destruction and stale callbacks; unconfigured IDs do not establish actual asset preload/permission behavior. Existing sixteen Contracts/Milestone groups and six-size UI checks pass. Pinned Selene/StyLua/Rojo and offline binding checks pass.

The user approved the ten-kit listening review and requested Roblox upload. `docs/evidence/style-starters/user-approval.json` pins the approved commit, manifest, review and all 160 sample hashes. Approved derivatives are frozen; changes require a new version. Hosted audio permissions/playback and cloud rejoin remain pending. The original kitchen/yard/workshop/rain task in #7 is not closed by these genre kits.

After the user enabled the extension's local-file permission, background Creator Dashboard uploads succeeded for **100 samples**: all 16 pads in Trip Hop, Dance, Grunge, Hard Trance, Hip Hop and Industrial, plus Pop pads 1–4. The remaining 12 Pop files failed at the quota boundary; Reggae, Techno and Trance were not submitted. The account shows **0 of 100 uploads remaining**, resetting **22 November 2026 at 12:51:51 PM** in the Dashboard's displayed time. No paid upload or automatic retry was performed.

`docs/evidence/style-starters/roblox-uploads.json` records owner CuuteFoxey, user 11274985967, exact source hashes, 100 real IDs and all 60 pending files. Canonical `data/content-ids.json` and its Luau projection bind the successful uploads; the source candidate manifest remains the frozen approval snapshot. The 14 image bindings and 24 original audio keys are preserved. Those original 24 audio files still await upload.

Studio MCP verified all 100 uploaded assets load in the owner's local Edit session and all 100 advance playback cursors in Client. The real AudioEngine passed 600 rapid playback submissions across those 100 pads, bounded selection, honest unconfigured states for the other 60, Stop, mute and teardown. Tests silenced their SoundGroup to avoid disturbing the user's work. Receipts are `roblox-studio-fetch.json`, `roblox-studio-client-playback.json` and `roblox-audio-engine.json` beside the upload ledger. These checks establish local owner-session engine behavior; they do not establish acoustic balance, physical latency or access in the still-uncreated private experience. No issue is closed on these results alone.

## Reproduction

```powershell
python -B tools/build_style_packs.py
python -B tools/build_style_packs.py --verify
python -B tools/project_style_packs.py
python -B tools/build_style_auditions.py
```

Initial build requires the ten named archives and refuses an existing candidate destination. `--refresh-derived` refuses user-approved audio as well as uploaded/bound style audio. Before approval, it verifies source hashes and refreshes note labels. It never modifies original copies. No new dependency, microphone capture, paid provider or external audio service was introduced.
