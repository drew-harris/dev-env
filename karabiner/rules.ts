import fs from "fs";
import { KarabinerRules } from "./types";
import {
  createHyperSubLayers,
  app,
  open,
  generateUnsetForEveryKey,
  superPress,
} from "./utils";

const BROWSER = "Zen";
const THISISMYTERM = "Ghostty";

const rules: KarabinerRules[] = [
  {
    description: "Hyper Key (⌃⌥⇧⌘)",
    manipulators: [
      // {
      //   // conditions: [
      //   //   { type: "device_if", identifiers: { is_built_in_keyboard: true } },
      //   // ],
      //   description: "I bought a dumb keyboard",
      //   from: {
      //     key_code: "left_control",
      //   },
      //   to: [{ key_code: "fn" }],
      //   type: "basic",
      // },
      // {
      //   description: "I bought a dumb keyboard part 2",
      //   // conditions: [
      //   //   { type: "device_if", identifiers: { is_built_in_keyboard: true } },
      //   // ],
      //   from: {
      //     key_code: "fn",
      //   },
      //   to: [{ key_code: "left_control" }],
      //   type: "basic",
      // },
      {
        description: "Right_CMd -> Hyper Key",
        from: {
          key_code: "right_command",
          modifiers: {
            optional: ["any"],
          },
        },
        to: [
          {
            set_variable: {
              name: "hyper",
              value: 1,
            },
          },
        ],
        to_after_key_up: [
          ...generateUnsetForEveryKey(),
          {
            set_variable: {
              name: "hyper",
              value: 0,
            },
          },
        ],
        type: "basic",
      },
      {
        description: "Caps lock escape",
        from: {
          key_code: "caps_lock",
        },
        to: [
          {
            key_code: "escape",
          },
        ],
        type: "basic",
      },
    ],
  },
  ...createHyperSubLayers({
    spacebar: open(
      "raycast://extensions/stellate/mxstbr-commands/create-notion-todo"
    ),

    q: app("Legcord"),
    c: app("Cursor"),
    i: app(TERMINAL),
    w: app("Element"),
    a: app(BROWSER),
    m: app("Messages"),
    z: app("Zed"),

    // b = "B"rowse
    b: {
      t: open("https://twitter.com"),
      r: open("https://reddit.com"),
      v: open("https://youtube.com"),
      c: open("https://smu.instructure.com/"),
      a: open("https://beta.t3.chat/chat"),
      l: open("https://librechat.drewh.net/c/new"),
    },

    h: open("raycast://extensions/raycast/clipboard-history/clipboard-history"),

    // o = "Open" applications
    o: {
      q: app("Legcord"),
      p: app("Firefox"),
      f: app("Finder"),
      i: app(TERMINAL),
      w: app("Element"),
      a: app("Arc"),
      m: app("Messages"),
      1: app("1Password"),
      n: app("Notes"),
      r: app("AI"),
      // Open todo list managed via *H*ypersonic
      z: app("zoom.us"),
      d: app("Figma"),
      s: app("Spotify"),
      c: app("Cursor"),
    },

    // spotify
    s: {
      l: superPress("l"),
      c: open(
        "https://open.spotify.com/album/1GG6U2SSJPHO6XsFiBzxYv?si=sAfC6AtNRFO8cavhPXTYBA"
      ),
      f: open("raycast://extensions/mattisssa/spotify-player/search"),
      n: open("raycast://extensions/mattisssa/spotify-player/nowPlaying"),
    },

    // d = "device"
    d: {
      u: {
        to: [
          {
            key_code: "volume_increment",
          },
        ],
      },
      j: {
        to: [
          {
            key_code: "volume_decrement",
          },
        ],
      },
      i: {
        to: [
          {
            key_code: "display_brightness_increment",
          },
        ],
      },
      k: {
        to: [
          {
            key_code: "display_brightness_decrement",
          },
        ],
      },
      l: {
        to: [
          {
            key_code: "q",
            modifiers: ["right_control", "right_command"],
          },
        ],
      },
      p: {
        to: [
          {
            key_code: "play_or_pause",
          },
        ],
      },
      semicolon: {
        to: [
          {
            key_code: "fastforward",
          },
        ],
      },
      h: {
        to: [
          {
            key_code: "rewind",
          },
        ],
      },
      // "D"o not disturb toggle
      d: open(
        `raycast://extensions/yakitrak/do-not-disturb/toggle?launchType=background`
      ),
      // "T"heme
      t: open(`raycast://extensions/raycast/system/toggle-system-appearance`),
      c: open("raycast://extensions/raycast/system/open-camera"),
      // 'v'oice
      v: {
        to: [
          {
            key_code: "spacebar",
            modifiers: ["left_option"],
          },
        ],
      },
    },

    // v = "moVe" which isn't "m" because we want it to be on the left hand
    // so that hjkl work like they do in vim
    v: {
      h: {
        to: [{ key_code: "left_arrow" }],
      },
      j: {
        to: [{ key_code: "down_arrow" }],
      },
      k: {
        to: [{ key_code: "up_arrow" }],
      },
      l: {
        to: [{ key_code: "right_arrow" }],
      },
    },

    // r = "Raycast"
    r: {
      c: open("raycast://extensions/thomas/color-picker/pick-color"),
      e: open(
        "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"
      ),
      // Yay
      y: open("raycast://extensions/raycast/raycast/confetti"),
      t: open("raycast://extensions/reboot/hypersonic/index"),
      h: open("raycast://extensions/mattisssa/spotify-player/nowPlaying"),
      f: open("raycast://extensions/raycast/raycast-focus/start-focus-session"),
      p: open("raycast://extensions/raycast/raycast-focus/pause-focus-session"),
      s: open(
        "raycast://extensions/raycast/raycast-focus/resume-focus-session"
      ),
    },
    equal_sign: {
      to: [
        {
          shell_command: "~/.config/scripts/shutdown.sh",
        },
      ],
    },
  }),
];

fs.writeFileSync(
  "karabiner.json",
  JSON.stringify(
    {
      global: {
        show_in_menu_bar: true,
      },
      profiles: [
        {
          name: "Default",
          complex_modifications: {
            rules,
          },
          virtual_hid_keyboard: { keyboard_type_v2: "ansi" },
        },
      ],
    },
    null,
    2
  )
);
