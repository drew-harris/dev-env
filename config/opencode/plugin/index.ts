import type { Plugin } from "@opencode-ai/plugin";

export const MyPlugin: Plugin = async ({ app, client, $ }) => {
  return {
    // event: async ({ event }) => {
    //   await $`osascript -e 'display notification "Session completed!" with title "opencode"'`;
    // },
    // async "chat.message"(input, output) {
    //   await $`osascript -e 'display notification "Session completed!" with title "opencode"'`;
    // },
  };
};
