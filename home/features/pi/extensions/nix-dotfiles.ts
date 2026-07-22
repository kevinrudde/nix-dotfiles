import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pi-dotfiles", {
    description: "Show where Pi is managed in nix-dotfiles",
    handler: async (_args, ctx) => {
      ctx.ui.notify(
        "Managed by ~/.config/nix-dotfiles/home/features/pi. Edit settings.json or extensions/, rebuild Home Manager, then /reload.",
        "info",
      );
    },
  });
}
