# Dotfiles

## Deploy

Uses GNU Stow to symlink configs into place.

```sh
stow nvim      # ~/.config/nvim
stow tmux      # ~/.tmux.conf
```

### Obsidian templates

```sh
cp -r obsidian-templates/* ~/main-vault/templates/
```

### wt — git worktree helper

Not stowed. Source it from `~/.zshrc`:

```sh
source ~/dotfiles/wt/wt.zsh
```

| Command | Effect |
|---|---|
| `wt` / `wt list` | list worktrees with indices, `*` marks current |
| `wt <n>` | `cd` to worktree `n` |
| `wt remove <n>` | `git worktree remove` that worktree (cds to index 0 first if it's the current one) |
| `wt add <branch>` | create worktree at `../<repo>-<branch>` and `cd` into it, branching if needed |
| `wt add <path> ...` | passthrough to `git worktree add` |
| `wt <anything>` | passthrough to `git worktree <anything>` |

Index 0 is always the main worktree. Tab completion lists indices with branch and path.
