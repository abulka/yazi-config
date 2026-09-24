# Yazi config (portable)

My [Yazi](https://yazi-rs.github.io/) file manager configuration, kept in git so
it's easy to set up on a new machine.

Repository: <https://github.com/abulka/yazi-config>

## Contents

- `keymap.toml` — custom keybindings (macOS + Windows, filtered per-OS with `for`)
- `yazi.toml` — openers / open rules
- `plugins/save-tabs.yazi/` — "save tabs" plugin (persist open tabs across sessions)
- `README.md` — this file
- `tabs.txt` is **gitignored** — it's machine-specific runtime state

## Quick setup

```sh
git clone https://github.com/abulka/yazi-config ~/.config/yazi
```

That's it — Yazi loads config and plugins from `~/.config/yazi`. Then add the
`y()` function below to your shell rc and make sure `yazi` is installed.

> On Windows, Yazi reads its config from `%AppData%\yazi` instead of
> `~/.config/yazi`. See [Windows (PowerShell)](#windows-powershell) below.

## Shell function: `y()`

`y()` opens Yazi in the current directory, **restores your saved tabs**, and
**`cd`s to the directory you exited in**.

One portable version works in **both bash and zsh** — no shell detection needed.
Paste it into `~/.zshrc` or `~/.bashrc`:

```sh
# y() - open Yazi, restore saved tabs, cd on exit (bash + zsh)
y() {
    local tmp cwd line tabs_file
    tabs_file="${YAZI_TABS_FILE:-$HOME/.config/yazi/tabs.txt}"
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    local tabs=() dedup=() i t
    [ -f "$tabs_file" ] && while IFS= read -r line; do
        [ -n "$line" ] && tabs+=("$line")
    done < "$tabs_file"
    tabs=("$PWD" "${tabs[@]}")
    for t in "${tabs[@]}"; do
        for i in "${dedup[@]}"; do [ "$i" = "$t" ] && continue 2; done
        dedup+=("$t")
    done
    command yazi "${dedup[@]}" --cwd-file="$tmp"
    cwd="$(cat "$tmp")"; rm -f -- "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && cd "$cwd"
}
```

- Reads saved tabs from `tabs.txt` (overridable via the `YAZI_TABS_FILE` env var).
- Always opens the current directory first, then saved tabs, deduplicated.
- Uses `mktemp -t ...` and `cat` — no bash/zsh-specific array tricks, so it runs
  on bash 3.2 (macOS), modern bash (Linux), and zsh.

## Windows (PowerShell)

Yazi on Windows looks for its config at `%AppData%\yazi`, **not**
`~/.config/yazi`. Point it at this repo by setting `YAZI_CONFIG_HOME` in your
PowerShell profile (`$PROFILE`):

```powershell
$Env:YAZI_CONFIG_HOME = "$env:USERPROFILE\.config\yazi"
```

Then add the PowerShell analogue of `y()`, which restores saved tabs and `cd`s
to the directory you exited in:

```powershell
function y {
    $tabsFile = $env:YAZI_TABS_FILE
    if (-not $tabsFile) { $tabsFile = "$env:USERPROFILE\.config\yazi\tabs.txt" }

    $tabs = @()
    if (Test-Path -LiteralPath $tabsFile) {
        $tabs = @(Get-Content -LiteralPath $tabsFile | Where-Object { $_ })
    }
    $tabs = @($PWD.Path) + $tabs

    $dedup = @()
    foreach ($t in $tabs) {
        if ($dedup -notcontains $t) { $dedup += $t }
    }

    $tmp = (New-TemporaryFile).FullName
    yazi.exe @dedup --cwd-file="$tmp"
    if (Test-Path $tmp) {
        $cwd = Get-Content -Path $tmp -Encoding UTF8
        if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd)) {
            Set-Location -LiteralPath $cwd
        }
        Remove-Item -Path $tmp -ErrorAction SilentlyContinue
    }
}
```

Notes:

- The `save-tabs` plugin needs no special setup on Windows — it writes to
  `$YAZI_CONFIG_HOME\tabs.txt` when that variable is set (falling back to
  `$HOME/.config/yazi/tabs.txt` on Unix). So the plugin and `y()` paths agree.
- The plugin no longer depends on `HOME`, which is usually unset on Windows.
- `keymap.toml` already carries Windows bindings (Explorer reveal, `start`,
  `pwsh`); macOS keys are unaffected thanks to the per-OS `for` filter.

## Keybindings

Custom (from `keymap.toml`):

| Key      | Action                                             |
| -------- | -------------------------------------------------- |
| `e`      | Open hovered file in VS Code                       |
| `b`      | Reveal hovered file in Explorer (Windows) / Finder (macOS) |
| `u`      | Copy hovered file's path                           |
| `C`      | Zip selection into `archive.zip` (blocking)        |
| `i`      | Save tabs (see plugin below)                       |
| `<C-p>`  | Open hovered with default app (Windows) / Quick Look of selection (macOS) |
| `!`      | Open `pwsh` (Windows) / `$SHELL` (Unix) here (blocking) |

OS-specific bindings are gated per key with `for = "windows"` / `for = "macos"`
in `keymap.toml`, so one portable file serves both platforms.

Notable defaults worth knowing:

| Key  | Action                                                        |
| ---- | ------------------------------------------------------------- |
| `:`  | Run a shell command in **block** mode (run-and-see)           |
| `;`  | Run a shell command in the **background** (fire-and-forget)   |
| `w`  | Task manager (progress + logs)                                |
| `s` / `S` | Search by filename (`fd`) / by content (`rg`)            |
| `f`  | Filter files                                                  |
| `/` / `?` | Find next / previous file                             |
| `y` / `x` / `p` | Yank / cut / paste                                   |
| `d` / `D` | Trash / permanently delete                               |
| `a` / `r` | Create file / rename                                      |
| `<Tab>` | Spot preview                                             |
| `~`  | Help                                                         |

## Tab persistence plugin (`save-tabs`)

- Press **`i`** inside Yazi to write up to the **8 most recent** open tab
  directories to `tabs.txt` (see
  [why 8, not 9](#why-the-plugin-saves-at-most-8-tabs-not-9)).
- Next time you run `y()`, those tabs are reopened alongside the current
  directory (deduplicated).
- The plugin writes to `$YAZI_CONFIG_HOME\tabs.txt` if that variable is set,
  otherwise `~/.config/yazi/tabs.txt` — the fallback used on Unix. The `y()`
  path must match the plugin's, so keep `YAZI_CONFIG_HOME` consistent (see the
  PowerShell section above).
- `tabs.txt` is machine-specific state and is **not committed** to git.
- The cap is `max_tabs` in `plugins/save-tabs.yazi/main.lua`.

### Why the plugin saves at most 8 tabs (not 9)

Yazi hard-limits tabs to **9**. Both halves of that limit are the same 9:

- The TUI refuses a 10th tab: *"Too many tabs — You can only open up to 9 tabs
  at the same time."*
- The CLI accepts at most 9 positional `[ENTRIES]`; a 10th makes Yazi refuse to
  start with
  `error: unexpected value '…' for '[ENTRIES]...' found; no more were expected`.

The plugin caps its save at **8** — one below Yazi's ceiling — because `y()`
**prepends `$PWD`** to the saved tabs before launching:

```text
args to yazi  =  $PWD  +  saved tabs   (deduplicated)
```

The file's line count isn't the only input; the shell's current directory is
added on top. So even a perfectly legal 9-line `tabs.txt` can overflow:

| Saved tabs | `$PWD` already among them?          | Args | Result           |
| ---------- | ----------------------------------- | ---- | ---------------- |
| 8          | either                              | ≤ 9  | starts           |
| 9          | yes — quit Yazi, run `y` right away | 9    | starts           |
| 9          | no — you `cd`'d elsewhere first     | 10   | refuses to start |

Capping saves at 8 guarantees the ≤ 9 case regardless of where you are when you
relaunch. The cost, when you have 9 tabs open and press `i`: only the 8 most
recent are written, and the oldest is dropped on the next restore.

This is a deliberate trade — `y()` stays simple (no shell-specific array tricks,
works on bash 3.2), so the guardrail lives in the plugin instead. To keep all 9
you'd need to raise `max_tabs` to 9 **and** have `y()` trim its argument list to
9 entries; raising the cap alone lets 9 saved tabs produce 10 arguments, and
Yazi refuses to start.

The plugin keeps the *most recent* tabs: it writes the last `max_tabs` entries
of `cx.tabs`, so the oldest are the ones dropped.

## Tips

### Shelling out (`:`, `;`, `!`)

- **`;`** runs in the background — output is captured into the task manager
  (press `w`), but only while the task is *running*. Instant commands finish
  before you can look, so don't use it to "see" output.
- **`:`** runs in block mode — output is shown live in the terminal, but Yazi
  redraws the instant the command exits. For output you need to read:
  - `: ls -l | less` (pager holds the terminal)
  - `: ls -l; read -s -n 1` (pause until a keypress)
- **`!`** drops you into a real shell — output persists until you `exit`. Use
  this when you need to actually read command output.
- Interactive programs (`fzf`, `lazygit`, `htop`, `$SHELL`) are best run with
  `:` or `!`.

### Task manager

- `w` opens it. `<Enter>` on a running background task shows a live output view.
- In the inspect view the **only** key that works is `q` (it's a raw-terminal
  passthrough — `^C` and `Esc` are ignored). `q` exits; the task keeps running.
- Back in the manager, **`x`** cancels/kills the selected task.

### ripgrep searches content, not filenames

- `rg muse*` treats `muse*` as a regex over file *contents*.
- To match files by name: `rg --files | rg muse` or `find . -name 'muse*'`.
