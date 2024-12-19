# nix-dotfiles

## Requirements

You need to install Nix, but we are not using their official installer. Instead, we are using the Determinate Systems Nix Installer. Just simply paste the following command into your terminal and you should be good to go:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Homebrew

Some applications need to be installed through homebrew, so we just install it.
* https://brew.sh/

### SOPS for secrets (optional)
If you want to have your secrets decrypted lying in the repository, you need to have you age key located at `/home/<username>/.config/sops/age/keys.txt` (linux) or `/Users/<username>/Library/Application Support/sops/age/keys.txt` (darwin)

## Setup

1. Clone the repository
```bash
git clone git@github.com:nickolaus/nix-dotfiles.git ~/.config/nix-dotfiles
```

2. Initialize the Nix setup with
```bash
nix run nix-darwin -- switch --flake ~/.config/nix-dotfiles
```

3. If you want to apply your changes in the future you need to run
```bash
darwin-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace
```
 
## MacOS Settings

### Keyboard

I am using the standard german layout, to have the same layout as Windows and Linux.
* Go to "Sytem Settings > Keyboard > Text Input".
* There you can change the layout by clicking on edit.
* Now another window is opening. Click on + in the left side to add another layout.
* Select German and then "German - Standard". Save it.

### Shortcuts

I have swapped my ctrl and cmd key on my external keyboard. You can simply do that aswell.
* Go to "Sytem Settings > Keyboard" and click on "Keyboard Shortcuts...".
* Switch to the "Modifier Keys" tab and select your external keyboard in the top
* Set Control to Command and Command to Control

### Change default shell

You can change your default shell with
```bash
chsh -s <Change this to your shell path which you can find in /etc/shells there is a comment with shells managed by nix> 
```