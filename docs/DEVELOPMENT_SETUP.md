# Development setup

## Local workstation status

Checked 2026-10-22:

- Roblox Studio is installed at `%LOCALAPPDATA%\Roblox\Versions\version-4f087c32742644ab\RobloxStudioBeta.exe`.
- Roblox Studio MCP is configured in Codex as `Roblox_Studio`; the server launcher exists, but its tools were not exposed to this task session.
- Rojo Studio plugin 7.7.0 is installed at `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm`.
- Rokit 1.2.0 is installed. The project pins Rojo 7.7.0, Selene 0.32.0, and StyLua 2.6.0 in `rokit.toml`.
- Node.js 22.23.2 and npm 12.0.2 are installed. Tripo CLI 0.7.2 is installed globally for planning and read-only account commands.
- Blender 5.2.2 is installed at `%ProgramFiles%\Blender Foundation\Blender 5.2\blender.exe`; the executable is not on `PATH`.
- The Tripo CLI has no configured API key. `tripo doctor` therefore skipped provider reachability and returned an unsuccessful connection check. No login was attempted.

## Daily commands

Run commands from the repository root so Rokit resolves project-pinned tools:

```powershell
rokit install
rojo build default.project.json --output work\FrequencyZero.rbxlx
rojo serve default.project.json
selene src
stylua --check src
```

The lint commands are available for developers; this setup did not run a test suite. Start Roblox Studio separately and connect the Rojo plugin to the local server. Use Blender with its full executable path if it is not added to `PATH`.

## Tripo inspection

For any Tripo CLI command, set the attribution environment variables in that PowerShell session first:

```powershell
$env:TRIPO_CLIENT_APP = 'codex'
$env:TRIPO_DISTRIBUTION_CHANNEL = 'codex_plugin'
tripo --version
tripo docs --llm
```

Use `--dry-run --json` to resolve a request without upload, network calls, or credits. The current `game-mobile` preset enables texturing/PBR and adds FBX conversion at a 2K texture size; that preset exceeds this project's default geometry-only policy. It must not be used for production requests without an approved, reviewed override.

Credentials remain in the Tripo CLI's external user profile. Never store them in this repository.
