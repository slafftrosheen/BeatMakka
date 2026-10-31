# Voice and sound direction — 2026-10-29

The user's direction is roughly 80% visual guidance and 20% explanatory text. Treat this as a design target, not a measured claim. Primary communication is an object highlight, navigable trail, demonstration, pad light, icon, or reward animation. Short text labels disambiguate; detailed instructions are requested through ?. Voice should reinforce these cues, never read the journal aloud.

## Implemented in this pass

Existing local samples provide the Echo Pads demonstration and response sounds, Pulse Club count-in, interface feedback and badge cue. The existing waterfront bed is retained. Music, ambience, UI cues and companion voices have separate session mix controls; subtitles have their own toggle. Music playback, jams, recording and street games suppress the waterfront bed. Global mute also covers companion speech. Six local speech clips were cut from the completed ElevenLabs auditions, with all four originals and provenance preserved in assets/production/needle-quay/voices. No additional environmental recordings were generated. The new voice integration has been packaged but not play-tested.

## Proposed voice production

The user selected warm, natural voices with short lines and explicitly selected the ElevenLabs plugin. Use original fictional character voices, with a relaxed neighborhood tone; no voice cloning. Keep most cues under two seconds. The first English audition batch is six clips, defined in `data/companion-voice-batch.v1.json`. The direct ElevenLabs connector is authenticated. Jessica (Alissia) and Robert - Warm & Reassuring (Nikolas) were selected from its voice catalog. Two audition takes per companion, each containing three cues, were submitted through eleven_v4 for a reported total of 332 credits. All four takes completed. The originals are preserved locally; take 1 for each companion was split at measured silent gaps into six mono 44.1kHz PCM clips and integrated in CompanionVoice. Studio runtime verification remains outstanding. See docs/evidence/playful-quay/voice-audition-submission.json for real generation IDs. Other languages and environmental recordings are outside this first batch.

| Trigger | Proposed subtitle / line | Visual already doing the work |
| --- | --- | --- |
| First echo round | “Listen. Your turn.” | Four illuminated pads demonstrate the phrase |
| Pulse count-in | “Ready? Here we go.” | Two visual/audio count-in beats |
| First completed activity | “Nice one!” | Companion cheer and badge banner |
| Explicit navigation help | “Over here.” | Arrow, route and highlighted destination |
| First recording | “Your pads. Your rhythm.” | Record lamp and pad input feedback |

Voice rules for the next implementation: separate Voice volume and subtitles controls; at most one line at a time; cancel a queued cue when its context ends; no unsolicited hints during recording/performance; a per-context cooldown of at least 30 seconds; keep player music untouched and duck only ambience under speech. No text-to-speech of user-authored titles or messages. Subtitles should remain available when voice is muted. Never require hearing a voice to complete an activity.

## Ambient recording list for a later asset pass

Waterfront: soft water, distant gulls and occasional harbor bell. Market: low non-verbal crowd murmur, crate handling and canvas movement. Cafe: quiet crockery and a door bell. Repair alley: ventilation and occasional tool sounds. Each should have a restrained positional radius, randomized gaps and independent voice limits. Avoid a continuous city-wide wall of sound. Use owned/cleared recordings and preserve their source/license metadata. Keep speech out of crowd beds so it does not imply real conversations or compete with gameplay.

## Visual assets and fonts

The cream faceplate was generated using the built-in imagegen tool and copied to assets/production/needle-quay/ui-hardware, with prompt and provenance. Labels remain live UI text. The tempo uses authored seven-segment geometry; instrument labels use Roblox's Code font. Icons are authored vector UI geometry, so they do not depend on emoji support or uploaded font/icon assets. Roblox supports images and EditableImage-backed ImageContent, including sprite sheets and sliced UI art: https://create.roblox.com/docs/reference/engine/classes/ImageLabel/ImageContent .


