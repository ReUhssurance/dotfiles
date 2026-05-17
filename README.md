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
