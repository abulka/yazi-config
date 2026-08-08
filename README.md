# Yazi config (portable)

My [Yazi](https://yazi-rs.github.io/) file manager configuration, kept in git so
it's easy to set up on a new machine.

## Contents

- `keymap.toml` — custom keybindings (macOS-flavoured)
- `yazi.toml` — openers / open rules
- `plugins/save-tabs.yazi/` — "save tabs" plugin (persist open tabs across sessions)
- `README.md` — this file
- `tabs.txt` is **gitignored** — it's machine-specific runtime state

## Quick setup

```sh
git clone <url> ~/.config/yazi
```

That's it — Yazi loads config and plugins from `~/.config/yazi`. Then add the
`y()` function below to your shell rc and make sure `yazi` is installed.

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

## Keybindings

Custom (from `keymap.toml`):

| Key      | Action                                             |
| -------- | -------------------------------------------------- |
| `e`      | Open hovered file in VS Code                       |
| `b`      | Reveal hovered file in Finder                      |
| `u`      | Copy hovered file's path                           |
| `C`      | Zip selection into `archive.zip` (blocking)        |
| `i`      | Save tabs (see plugin below)                       |
| `<C-p>`  | Quick Look preview of selection (macOS)            |
| `!`      | Open `$SHELL` here (blocking)                      |

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

- Press **`i`** inside Yazi to write all open tab directories to
  `~/.config/yazi/tabs.txt`.
- Next time you run `y()`, those tabs are reopened alongside the current
  directory (deduplicated).
- The plugin path and the `y()` path must agree — both default to
  `$HOME/.config/yazi/tabs.txt`.
- `tabs.txt` is machine-specific state and is **not committed** to git.

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
