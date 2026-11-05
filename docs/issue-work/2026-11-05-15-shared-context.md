# Issue #15 — explicit shared tuning context

The existing two-person protocol already supported invited roles, tempo proposals, handover, departure boundaries and mutually accepted joint copies. Its missing code boundary was the declared key/pitch context: participants could change pitch settings and publish without any contextual acknowledgement.

## Changes

- JamProtocol derives a compact declaration from the selected source role: the manifest's planned key (or mixed/unavailable palette), exact pad pitch offsets, and an explicit statement that tuning is not listening-verified. No source pitch, sample, note or tempo is retuned by this declaration.
- Context and snapshot capture share the same resolver/role filter. Muted, solo-excluded and zero-gain notes contribute no declared assignments or pitch offsets; genuine audible role notes with unavailable audio reject both operations. The context retains the original project/sequence revision token, and the server supplies the same unlock policy and session tempo to both paths.
- The existing schema-3 request envelope is retained. Start, Accept, Publish and role-exchange actions carry an acknowledged source-context token through `packet.value`. The UI presents the declaration and requires a second deliberate press, bound to the source and current jam revision. Focus loss, navigation and session changes invalidate confirmation.
- Invitations bind the host's reviewed recipient context. A recipient whose source has changed must obtain a fresh invitation. Acceptance also uses the current revision of the shared session.
- A publish that changes the accepted pitch/key declaration proposes that exact immutable part to the partner. Accept queues it at the existing next-bar boundary; decline, expiry or departure retains the accepted parts. An ordinary note edit with the same pitch/key context retains the established publish workflow.
- Role exchange exposes both captured declarations, and acceptance refuses a changed recipient source. Existing tempo consent, conductor handover, two seats, bounded voice allocation and joint-copy rules remain.
- Public jam dependencies are built from musical fields only. Project, section, kit and part names use fixed public labels; unrelated private metadata, unused pad assignments and other musical objects are not copied into another player's jam snapshot. This avoids exporting raw stored custom names without introducing a yielding filtering race. The owner's stored work remains untouched.

## Evidence and boundaries

Reviewed the current #15 brief and traced declarations, request revisions, invitations, proposals, queue application, departure and playback resolution in source. Scoped whitespace checks passed. No tests, Studio execution, actual two-client timing/audio, physical input or novice observations were performed. Planned key and pitch offsets do not establish a verified acoustic key or musical compatibility.

The coordinating batch separately pauses personal transport through the existing workspace stop function on entering a jam, so leaving cannot restart a stale personal playing packet.

No new dependency, networking architecture, asset upload/publication, spending, commit or push was introduced.

The final integration pass binds invite confirmation to the recipient UserId, clears it on target changes, and derives declarations only from the accepted audible role resolver. Jam entry pauses the actual personal transport rather than only its UI flags. Safe source attribution and release/version lineage survive accepted contribution snapshots and joint copies, with explicit credit/version capacity refusals. No source is retuned or overwritten.
