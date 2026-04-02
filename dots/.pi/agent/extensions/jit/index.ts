import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import chalk from "chalk";

export default function (pi: ExtensionAPI) {
  let jitEnabled = false;

  pi.registerCommand("jit", {
    async handler(_args, ctx) {
      jitEnabled = !jitEnabled;
      ctx.ui.setStatus(
        "jit",
        "jit: " + (jitEnabled ? chalk.green("enabled") : chalk.red("disabled")),
      );
    },
  });

  pi.on("session_start", (_ev, ctx) => {
    ctx.ui.setStatus(
      "jit",
      "jit: " + (jitEnabled ? chalk.green("enabled") : chalk.red("disabled")),
    );
  });

  pi.on("message_start", (_ev, _ctx) => {});
}
