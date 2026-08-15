import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Remove the reverse-video software cursor drawn by pi's editor. The TUI still
// positions the terminal's hardware cursor at the same location.
const SOFTWARE_CURSOR_RE = /\x1b\[7m([^\x1b]*)\x1b\[0m/;

class HardwareCursorEditor extends CustomEditor {
	override render(width: number): string[] {
		return super.render(width).map((line) => line.replace(SOFTWARE_CURSOR_RE, "$1"));
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			tui.setShowHardwareCursor(true);
			return new HardwareCursorEditor(tui, theme, keybindings);
		});
	});
}
