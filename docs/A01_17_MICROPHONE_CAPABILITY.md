# A01-17 / issue #19 — microphone capture decision

Verified 23 October 2026. **Do not implement or advertise real-world microphone sampling.** This research issue resolves to a demonstrated platform restriction, as its acceptance criteria permit. It does not certify a live microphone, persistent recording or publication route.

## Dated capability matrix

| Capability | Current result | Evidence and practical meaning |
| --- | --- | --- |
| Live voice communication | Supported only for eligible users/experiences | [Voice Chat](https://create.roblox.com/docs/chat/voice-chat) describes opt-in live communication for eligible age-verified 13+ users. This excludes younger children from a universal microphone flow and grants no sampler storage permission. |
| Microphone input stream | Voice input, not a saved sample | [AudioDeviceInput](https://create.roblox.com/docs/reference/engine/classes/AudioDeviceInput) represents device input; its Active state is controlled by core scripts. No microphone was created, enabled or inspected in this task. |
| AudioRecorder API shape | Exposed class/methods; recording unavailable | The [official recorder description](https://create.roblox.com/docs/reference/engine/classes/AudioRecorder) explicitly says the API is in development and unavailable. Studio 0.744.0.7441077 allows constructing the class but CanRecordAsync errors: `AudioRecorder is not enabled yet`. Class existence is not functional support. |
| Record AudioDeviceInput | Unsupported | The recorder description and GetUnrecordableInstancesAsync documentation exclude AudioDeviceInput. No graph was connected and no RecordAsync call was made. |
| Temporary recorded playback | Described future/session-local facility | Recorder documentation describes a 60-second bound and GetTemporaryContent usable only in the current session. This does not provide a durable asset or cross-session save. |
| Playback/trim of an existing allowed asset | Available separately from capture | [AudioPlayer](https://create.roblox.com/docs/reference/engine/classes/AudioPlayer) exposes playback/loop regions and playback speed. Those controls do not authorize recording or publishing microphone input. |
| Durable upload and sharing | Separate creator pipeline | [Audio assets](https://create.roblox.com/docs/audio/assets) describes creator imports, moderation, private assets and experience permissions. No tested public microphone-to-asset path is established by the recorder APIs. |
| Collect authored game sounds | Existing project path | WorldBuilder maps I01/I02/I03 to metal_hit/vent_thump/robot_chirp; MusicService handles their discovery and SampleCatalog enforces unlocks. These are developer-authored samples, not live microphone capture. |

## Reproducible non-recording Studio check

[tools/probe_audio_capture.luau](../tools/probe_audio_capture.luau) constructs one unparented recorder, inspects method availability, calls CanRecordAsync under pcall and destroys it. It creates no microphone, wires or output and captures no audio. It changes no communication, OS or account settings. [Actual receipt](evidence/a01-17/capability-probe.json) records the engine version, local PlaceId/UniverseID=0, exposed methods and the disabled-API error. This is an Edit-context capability observation, not a test on eligible live voice users.

[Documentation receipt](evidence/a01-17/docs-receipt.json) records the current official sources, including the recorder Markdown's `last_updated=2026-10-22T23:20:30Z`. The HTML summary lists methods without the crucial availability prose; the full official Markdown was retrieved through Studio MCP before deciding. Source assertions and observed engine behavior agree on the unavailable result.

## UX to retain now

Keep collecting sounds at named quay objects and assigning the unlocked catalog sample to a pad. Describe this as collecting a **game sound**. Do not show a microphone permission prompt, recording meter or control that pretends to capture the room. Keep the original library and approved CC0 source revisions under developer control. No child-recording portal, voice upload, credential-bearing helper or external capture service is introduced.

## Conditional future capture flow — specification only

Reconsider only after all release conditions below pass. The product proposal is deliberately bounded:

1. An eligibility/capability check precedes any capture UI. Explain what will be captured and where it can go; enter only after an explicit user action and platform-required consent. An ineligible user keeps the complete game-sound collection flow.
2. **Start** is explicit and shows an unmistakable recording state, duration and **Stop**. Permission denial, focus loss, device removal or reaching the product's chosen short limit ends capture and offers a clear retry/cancel. No background capture or automatic resumption.
3. Stop leads to a private **Preview** draft with Play/Stop, simple start/end trim markers and an easy **Delete** action. Preview and trim remain separate from acceptance; new capture must not erase an accepted pad sound without confirmation.
4. **Accept** assigns the reviewed draft only if the platform permits that use. Explain whether it lasts for this session. Do not silently claim a cloud save. **Delete/Cancel** clears the draft and disconnects any input graph.
5. Persistence and multiplayer sharing require separate decisions: eligible ages/consent, ownership, allowed recipients, moderation, retention/deletion and actual usage permissions. The default proposal is no sharing. A local/private preview never automatically becomes an uploaded or public asset.

These are proposed state/interaction rules, not implemented controls or a promise that Roblox will expose the necessary APIs.

## Conditions for reopening implementation

- Official public documentation must remove the unavailable restriction and explicitly permit the desired microphone source to be recorded.
- A supported, permission-respecting probe must succeed in the intended live experience and account/device eligibility matrix; class construction alone is insufficient.
- Establish whether output is temporary, exportable or persistently hosted, with actual supported API and permission evidence for each intended use.
- Agree the eligible age/consent model, explicit capture UX, storage/retention/deletion, rights and moderation before implementing persistence or sharing.
- Validate stop/cancel/denial/focus-loss behavior and prove that no data is captured, retained or shared outside the user's deliberate action.

Until these conditions change, the supported product direction remains virtual collection of licensed game sounds. The issue can close as completed research with an unsupported verdict; microphone implementation remains deferred.
