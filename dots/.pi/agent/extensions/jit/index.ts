import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";

const STATE_ENTRY = "jit-state";
const COMMIT_ENTRY = "jit-commit";
const DATA_VERSION = 2;
const JJ_TIMEOUT_MS = 30_000;
const COMMIT_ID_PATTERN = /^[0-9a-f]{16,128}$/;

interface EnabledStateData {
  version: typeof DATA_VERSION;
  enabled: true;
  repoRoot: string;
  baseParents: string[];
  headCommitId?: string;
  headChangeId?: string;
  allowEmptyChild?: boolean;
}

interface DisabledStateData {
  version: typeof DATA_VERSION;
  enabled: false;
}

interface ParsedEnabledState {
  version: 1 | typeof DATA_VERSION;
  enabled: true;
  repoRoot: string;
  baseParents: string[];
  headCommitId?: string;
  headChangeId?: string;
  allowEmptyChild: boolean;
}

interface CommitData {
  version: typeof DATA_VERSION;
  repoRoot: string;
  commitId: string;
  changeId: string;
  conversationEntryId: string | null;
  promptEntryId: string | null;
  title: string;
  files: string[];
}

interface ParsedCommitData {
  repoRoot: string;
  commitId: string;
  changeId: string;
  conversationEntryId: string | null;
  title: string;
  files: string[];
}

interface ResolvedState {
  enabled: boolean;
  repoRoot?: string;
  baseParentCommitIds: string[];
  headCommitId?: string;
  headChangeId?: string;
  allowEmptyChild: boolean;
}

interface WorkingCopy {
  commitId: string;
  changeId: string;
  empty: boolean;
  described: boolean;
  parentCommitIds: string[];
}

interface PromptBaseline {
  repoRoot: string;
  changeId: string;
  prompt: string;
}

interface TreeRestorePlan {
  restoreFiles: boolean;
  repoRoot: string;
  targetState: ResolvedState;
  targetCommitId?: string;
  keepFilesState: EnabledStateData;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isCommitId(value: unknown): value is string {
  return typeof value === "string" && COMMIT_ID_PATTERN.test(value);
}

function hasCommitIds(value: unknown): value is string[] {
  return Array.isArray(value) && value.every(isCommitId);
}

function parseStateData(value: unknown): ParsedEnabledState | DisabledStateData | undefined {
  if (!isRecord(value) || (value.version !== 1 && value.version !== DATA_VERSION)) {
    return undefined;
  }

  if (value.enabled === false) {
    return { version: DATA_VERSION, enabled: false };
  }

  if (
    value.enabled !== true ||
    typeof value.repoRoot !== "string" ||
    !hasCommitIds(value.baseParents)
  ) {
    return undefined;
  }

  const headCommitId = isCommitId(value.headCommitId) ? value.headCommitId : undefined;
  const headChangeId =
    typeof value.headChangeId === "string" ? value.headChangeId : undefined;
  return {
    version: value.version,
    enabled: true,
    repoRoot: value.repoRoot,
    baseParents: value.baseParents,
    headCommitId,
    headChangeId,
    allowEmptyChild: value.allowEmptyChild === true,
  };
}

function parseCommitData(value: unknown): ParsedCommitData | undefined {
  if (
    !isRecord(value) ||
    (value.version !== 1 && value.version !== DATA_VERSION) ||
    typeof value.repoRoot !== "string" ||
    !isCommitId(value.commitId) ||
    typeof value.changeId !== "string" ||
    typeof value.title !== "string" ||
    !Array.isArray(value.files) ||
    !value.files.every((file) => typeof file === "string")
  ) {
    return undefined;
  }

  const rawEntryId =
    value.version === 1 ? value.turnEntryId : value.conversationEntryId;
  if (rawEntryId !== null && typeof rawEntryId !== "string") return undefined;
  const conversationEntryId = rawEntryId as string | null;

  return {
    repoRoot: value.repoRoot,
    commitId: value.commitId,
    changeId: value.changeId,
    conversationEntryId,
    title: value.title,
    files: value.files as string[],
  };
}

function branchAt(ctx: ExtensionContext, leafId: string | null): SessionEntry[] {
  return leafId === null ? [] : ctx.sessionManager.getBranch(leafId);
}

function resolveState(
  ctx: ExtensionContext,
  leafId: string | null = ctx.sessionManager.getLeafId(),
): ResolvedState {
  const branch = branchAt(ctx, leafId);
  const commitsByConversationEntry = new Map<string, ParsedCommitData>();

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type !== "custom" || entry.customType !== COMMIT_ENTRY) continue;
    const commit = parseCommitData(entry.data);
    if (commit?.conversationEntryId) {
      commitsByConversationEntry.set(commit.conversationEntryId, commit);
    }
  }

  let state: ResolvedState = {
    enabled: false,
    baseParentCommitIds: [],
    allowEmptyChild: false,
  };

  const setHead = (commit: ParsedCommitData) => {
    if (!state.enabled || state.repoRoot !== commit.repoRoot) return;
    state.headCommitId = commit.commitId;
    state.headChangeId = commit.changeId;
    state.allowEmptyChild = false;
  };

  for (const entry of branch) {
    if (entry.type === "custom" && entry.customType === STATE_ENTRY) {
      const saved = parseStateData(entry.data);
      if (saved?.enabled) {
        // Version 1 used a state entry after /tree as a checkpoint whose sole
        // parent was the selected Pi commit. Preserve that meaning on upgrade.
        const legacyCheckpointHead =
          saved.version === 1 && state.headCommitId && saved.baseParents.length === 1
            ? saved.baseParents[0]
            : undefined;
        state = {
          enabled: true,
          repoRoot: saved.repoRoot,
          baseParentCommitIds: [...saved.baseParents],
          headCommitId: saved.headCommitId ?? legacyCheckpointHead,
          headChangeId: saved.headChangeId,
          allowEmptyChild: saved.allowEmptyChild,
        };
      } else if (saved) {
        state = {
          enabled: false,
          baseParentCommitIds: [],
          allowEmptyChild: false,
        };
      }
    }

    if (
      state.enabled &&
      state.headCommitId &&
      entry.type === "message" &&
      entry.message.role === "user"
    ) {
      state.allowEmptyChild = true;
    }

    const conversationCommit = commitsByConversationEntry.get(entry.id);
    if (conversationCommit) setHead(conversationCommit);

    if (entry.type === "custom" && entry.customType === COMMIT_ENTRY) {
      const commit = parseCommitData(entry.data);
      if (commit) setHead(commit);
    }
  }

  return state;
}

function messageText(message: unknown): string {
  if (!isRecord(message)) return "";
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (block): block is { type: "text"; text: string } =>
        isRecord(block) && block.type === "text" && typeof block.text === "string",
    )
    .map((block) => block.text)
    .join("\n");
}

function latestUserEntry(ctx: ExtensionContext): { id: string; text: string } | undefined {
  const branch = ctx.sessionManager.getBranch();
  for (let index = branch.length - 1; index >= 0; index--) {
    const entry = branch[index];
    if (entry.type === "message" && entry.message.role === "user") {
      return { id: entry.id, text: messageText(entry.message) };
    }
  }
  return undefined;
}

function conciseText(text: string, maxLength = 120): string {
  const firstLine = text
    .split("\n")
    .map((line) => line.trim())
    .find(Boolean);
  if (!firstLine) return "";

  const cleaned = firstLine
    .replace(/^#{1,6}\s+/, "")
    .replace(/^[-*+]\s+/, "")
    .replace(/^[*_`]+|[*_`]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();

  if (cleaned.length <= maxLength) return cleaned;
  return `${cleaned.slice(0, maxLength - 1).trimEnd()}…`;
}

function limitFileSummary(files: string[], limit = 100): string[] {
  if (files.length <= limit) return files;
  return [...files.slice(0, limit), `… ${files.length - limit} more files`];
}

function promptDescription(prompt: string): string {
  const message = prompt.trim() || "(empty user message)";
  return message.startsWith("pi:") ? message : `pi: ${message}`;
}

function sameCommitIds(left: string[], right: string[]): boolean {
  const sortedLeft = [...left].sort();
  const sortedRight = [...right].sort();
  return (
    sortedLeft.length === sortedRight.length &&
    sortedLeft.every((commitId, index) => commitId === sortedRight[index])
  );
}

function isEmptyChildOf(workingCopy: WorkingCopy, commitId: string): boolean {
  return (
    workingCopy.empty &&
    !workingCopy.described &&
    workingCopy.parentCommitIds.length === 1 &&
    workingCopy.parentCommitIds[0] === commitId
  );
}

export default function (pi: ExtensionAPI) {
  let activePrompt: PromptBaseline | undefined;
  let awaitingInitialUserMessage = false;
  let pendingTreeRestore: TreeRestorePlan | undefined;
  let statusError: string | undefined;

  const runJj = async (args: string[], cwd: string) => {
    const result = await pi.exec(
      "jj",
      ["--color", "never", "--no-pager", ...args],
      { cwd, timeout: JJ_TIMEOUT_MS },
    );
    if (result.code !== 0) {
      const detail = result.stderr.trim() || result.stdout.trim() || `exit ${result.code}`;
      throw new Error(`jj ${args[0]} failed: ${detail}`);
    }
    return result.stdout;
  };

  const findRepoRoot = async (cwd: string): Promise<string> => {
    return (await runJj(["root"], cwd)).trim();
  };

  const readWorkingCopy = async (repoRoot: string): Promise<WorkingCopy> => {
    const template =
      'commit_id ++ "|" ++ change_id ++ "|" ++ if(empty, "1", "0") ++ "|" ++ description.len() ++ "|" ++ parents.map(|p| p.commit_id()).join(",")';
    const output = (await runJj(
      ["log", "--no-graph", "--revisions", "@", "--template", template],
      repoRoot,
    )).trim();
    const [commitId, changeId, empty, descriptionLength, parents = ""] = output.split("|");

    if (
      !isCommitId(commitId) ||
      !changeId ||
      (empty !== "0" && empty !== "1") ||
      !/^\d+$/.test(descriptionLength)
    ) {
      throw new Error(`Could not parse jj working-copy state: ${output}`);
    }

    const parentCommitIds = parents ? parents.split(",") : [];
    if (!parentCommitIds.every(isCommitId)) {
      throw new Error(`Could not parse jj parent commits: ${parents}`);
    }

    return {
      commitId,
      changeId,
      empty: empty === "1",
      described: descriptionLength !== "0",
      parentCommitIds,
    };
  };

  const resolveLiveHeadCommitId = async (
    repoRoot: string,
    state: ResolvedState,
  ): Promise<string | undefined> => {
    if (!state.headChangeId) return state.headCommitId;
    try {
      const output = await runJj(
        [
          "log",
          "--no-graph",
          "--revisions",
          state.headChangeId,
          "--template",
          'commit_id ++ ","',
        ],
        repoRoot,
      );
      const commitIds = output.split(",").filter(isCommitId);
      return commitIds.length === 1 ? commitIds[0] : state.headCommitId;
    } catch {
      return state.headCommitId;
    }
  };

  const showStatus = (ctx: ExtensionContext, state = resolveState(ctx)) => {
    const theme = ctx.ui.theme;
    if (statusError) {
      ctx.ui.setStatus("jit", theme.fg("error", "jit: error"));
    } else if (state.enabled) {
      ctx.ui.setStatus("jit", theme.fg("success", "jit: enabled"));
    } else {
      ctx.ui.setStatus("jit", theme.fg("dim", "jit: disabled"));
    }
  };

  const reportError = (ctx: ExtensionContext, message: string) => {
    statusError = message;
    showStatus(ctx);
    ctx.ui.notify(`JIT: ${message}`, "error");
  };

  const ensureRepo = async (ctx: ExtensionContext, state: ResolvedState): Promise<string> => {
    if (!state.enabled || !state.repoRoot) {
      throw new Error("the active Pi branch does not have JIT enabled");
    }
    const actualRoot = await findRepoRoot(ctx.cwd);
    if (actualRoot !== state.repoRoot) {
      throw new Error(`session tracks ${state.repoRoot}, but the current jj repo is ${actualRoot}`);
    }
    return state.repoRoot;
  };

  const workingCopyMatchesState = (
    workingCopy: WorkingCopy,
    state: ResolvedState,
  ): boolean => {
    if (state.headCommitId) {
      return (
        workingCopy.commitId === state.headCommitId ||
        (!!state.headChangeId && workingCopy.changeId === state.headChangeId) ||
        isEmptyChildOf(workingCopy, state.headCommitId)
      );
    }
    return (
      workingCopy.empty &&
      !workingCopy.described &&
      sameCommitIds(workingCopy.parentCommitIds, state.baseParentCommitIds)
    );
  };

  const ensureCanLeaveState = async (ctx: ExtensionContext, state: ResolvedState) => {
    const repoRoot = await ensureRepo(ctx, state);
    await readWorkingCopy(repoRoot);
  };

  const alignWorkingCopy = async (ctx: ExtensionContext, state: ResolvedState) => {
    const repoRoot = await ensureRepo(ctx, state);
    const workingCopy = await readWorkingCopy(repoRoot);

    if (state.headCommitId) {
      const headCommitId = (await resolveLiveHeadCommitId(repoRoot, state)) ?? state.headCommitId;
      if (workingCopy.commitId === headCommitId) return;
      if (state.headChangeId && workingCopy.changeId === state.headChangeId) return;
      if (state.allowEmptyChild && isEmptyChildOf(workingCopy, headCommitId)) return;
      if (!workingCopy.empty || workingCopy.described) return;
      await runJj(["edit", headCommitId], repoRoot);
      return;
    }

    if (
      workingCopy.empty &&
      !workingCopy.described &&
      sameCommitIds(workingCopy.parentCommitIds, state.baseParentCommitIds)
    ) {
      return;
    }
    if (!workingCopy.empty || workingCopy.described) return;
    if (state.baseParentCommitIds.length === 0) {
      throw new Error("the tracked Jujutsu base has no parent commits");
    }
    await runJj(["new", ...state.baseParentCommitIds], repoRoot);
  };

  const checkpointForWorkingCopy = (
    repoRoot: string,
    workingCopy: WorkingCopy,
    sourceState: ResolvedState,
  ): EnabledStateData => {
    if (
      sourceState.enabled &&
      sourceState.repoRoot === repoRoot &&
      workingCopyMatchesState(workingCopy, sourceState)
    ) {
      return {
        version: DATA_VERSION,
        enabled: true,
        repoRoot,
        baseParents: sourceState.baseParentCommitIds,
        headCommitId: sourceState.headCommitId,
        headChangeId: sourceState.headChangeId,
        allowEmptyChild:
          !!sourceState.headCommitId && isEmptyChildOf(workingCopy, sourceState.headCommitId),
      };
    }

    if (workingCopy.described) {
      return {
        version: DATA_VERSION,
        enabled: true,
        repoRoot,
        baseParents: workingCopy.parentCommitIds,
        headCommitId: workingCopy.commitId,
        headChangeId: workingCopy.changeId,
        allowEmptyChild: false,
      };
    }

    return {
      version: DATA_VERSION,
      enabled: true,
      repoRoot,
      baseParents: workingCopy.parentCommitIds,
      allowEmptyChild: false,
    };
  };

  const treeRestorePreview = async (
    repoRoot: string,
    targetCommitId: string,
  ): Promise<{ changeId: string; preview: string }> => {
    const changeId = (
      await runJj(
        [
          "log",
          "--no-graph",
          "--revisions",
          targetCommitId,
          "--template",
          "change_id.shortest(8)",
        ],
        repoRoot,
      )
    ).trim();
    const description = (
      await runJj(
        [
          "log",
          "--no-graph",
          "--revisions",
          targetCommitId,
          "--template",
          "description.first_line()",
        ],
        repoRoot,
      )
    ).trim();
    const changedFiles = (await runJj(
      ["diff", "--from", "@", "--to", targetCommitId, "--summary"],
      repoRoot,
    ))
      .split("\n")
      .map((line) => line.trimEnd())
      .filter(Boolean);
    const shownFiles = changedFiles.slice(0, 6);
    const preview = [
      description || "(no description)",
      "",
      changedFiles.length === 0 ? "No file changes from the current @." : "File changes from the current @:",
      ...shownFiles,
      ...(changedFiles.length > shownFiles.length
        ? [`… ${changedFiles.length - shownFiles.length} more files`]
        : []),
    ].join("\n");

    return { changeId, preview };
  };

  const prepareWorkingCopyForPrompt = async (
    ctx: ExtensionContext,
    state: ResolvedState,
  ): Promise<WorkingCopy> => {
    const repoRoot = await ensureRepo(ctx, state);
    let workingCopy = await readWorkingCopy(repoRoot);
    const isTrackedHead =
      (state.headCommitId && workingCopy.commitId === state.headCommitId) ||
      (state.headChangeId && workingCopy.changeId === state.headChangeId);

    if (isTrackedHead || workingCopy.described) {
      // Preserve the completed/manual change and start the user's new change on
      // top of the exact working copy they currently have.
      await runJj(["new", workingCopy.commitId], repoRoot);
      workingCopy = await readWorkingCopy(repoRoot);
    }

    // An empty or non-empty undescribed @ is intentionally adopted. This lets
    // the user make manual edits before sending the next message.
    return workingCopy;
  };

  const beginPrompt = async (ctx: ExtensionContext, prompt: string): Promise<boolean> => {
    const state = resolveState(ctx);
    if (!state.enabled || !state.repoRoot) {
      activePrompt = undefined;
      return false;
    }

    try {
      const workingCopy = await prepareWorkingCopyForPrompt(ctx, state);
      await runJj(["describe", "--message", promptDescription(prompt)], state.repoRoot);
      const described = await readWorkingCopy(state.repoRoot);
      activePrompt = {
        repoRoot: state.repoRoot,
        changeId: described.changeId,
        prompt,
      };
      statusError = undefined;
      showStatus(ctx, state);
      return true;
    } catch (error) {
      activePrompt = undefined;
      reportError(ctx, error instanceof Error ? error.message : String(error));
      return false;
    }
  };

  const finalizePrompt = async (ctx: ExtensionContext): Promise<boolean> => {
    const baseline = activePrompt;
    if (!baseline) return true;

    try {
      const state = resolveState(ctx);
      if (!state.enabled || state.repoRoot !== baseline.repoRoot) {
        activePrompt = undefined;
        return true;
      }

      let workingCopy = await readWorkingCopy(baseline.repoRoot);
      if (workingCopy.changeId !== baseline.changeId || !workingCopy.described) {
        // If the user moved around with jj while the agent was running, adopt
        // the current change instead of blocking their workflow.
        await runJj(
          ["describe", "--message", promptDescription(baseline.prompt)],
          baseline.repoRoot,
        );
        workingCopy = await readWorkingCopy(baseline.repoRoot);
      }

      const changedFiles = (await runJj(
        ["diff", "--revisions", "@", "--summary"],
        baseline.repoRoot,
      ))
        .split("\n")
        .map((line) => line.trimEnd())
        .filter(Boolean);

      if (changedFiles.length === 0) {
        // Describing at prompt start creates an empty change when no files were
        // touched. Abandon it so no-op messages still disappear from the graph.
        await runJj(["abandon", "@"], baseline.repoRoot);
        activePrompt = undefined;
        return true;
      }

      const files = limitFileSummary(changedFiles);
      const conversationEntryId = ctx.sessionManager.getLeafId();
      const promptEntry = latestUserEntry(ctx);
      const prompt = promptEntry?.text || baseline.prompt;
      const committed = await readWorkingCopy(baseline.repoRoot);
      const title = promptDescription(conciseText(prompt));

      const data: CommitData = {
        version: DATA_VERSION,
        repoRoot: baseline.repoRoot,
        commitId: committed.commitId,
        changeId: committed.changeId,
        conversationEntryId,
        promptEntryId: promptEntry?.id ?? null,
        title,
        files,
      };
      pi.appendEntry(COMMIT_ENTRY, data);
      activePrompt = undefined;
      statusError = undefined;
      showStatus(ctx);
      ctx.ui.notify(`JIT recorded ${committed.changeId.slice(0, 8)}: ${title}`, "info");
      return true;
    } catch (error) {
      reportError(ctx, error instanceof Error ? error.message : String(error));
      return false;
    }
  };

  const targetLeafId = (ctx: ExtensionContext, targetId: string): string | null => {
    const target = ctx.sessionManager.getEntry(targetId);
    if (!target) return null;
    if (
      (target.type === "message" && target.message.role === "user") ||
      target.type === "custom_message"
    ) {
      return target.parentId;
    }
    return target.id;
  };

  pi.registerCommand("jit", {
    description: "Toggle per-user-message Jujutsu commits",
    async handler(_args, ctx) {
      const current = resolveState(ctx);
      activePrompt = undefined;
      awaitingInitialUserMessage = false;
      pendingTreeRestore = undefined;
      statusError = undefined;

      if (current.enabled) {
        const data: DisabledStateData = { version: DATA_VERSION, enabled: false };
        pi.appendEntry(STATE_ENTRY, data);
        showStatus(ctx, {
          enabled: false,
          baseParentCommitIds: [],
          allowEmptyChild: false,
        });
        ctx.ui.notify("JIT disabled", "info");
        return;
      }

      try {
        const repoRoot = await findRepoRoot(ctx.cwd);
        const workingCopy = await readWorkingCopy(repoRoot);

        const data: EnabledStateData = {
          version: DATA_VERSION,
          enabled: true,
          repoRoot,
          baseParents: workingCopy.parentCommitIds,
          headCommitId: workingCopy.described ? workingCopy.commitId : undefined,
          headChangeId: workingCopy.described ? workingCopy.changeId : undefined,
          allowEmptyChild: false,
        };
        pi.appendEntry(STATE_ENTRY, data);
        showStatus(ctx, {
          enabled: true,
          repoRoot,
          baseParentCommitIds: workingCopy.parentCommitIds,
          headCommitId: data.headCommitId,
          headChangeId: data.headChangeId,
          allowEmptyChild: false,
        });
        ctx.ui.notify(`JIT enabled for ${repoRoot}`, "info");
      } catch (error) {
        reportError(ctx, error instanceof Error ? error.message : String(error));
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    activePrompt = undefined;
    awaitingInitialUserMessage = false;
    pendingTreeRestore = undefined;
    statusError = undefined;
    const state = resolveState(ctx);

    if (state.enabled) {
      try {
        await alignWorkingCopy(ctx, state);
      } catch (error) {
        reportError(ctx, error instanceof Error ? error.message : String(error));
        return;
      }
    }
    showStatus(ctx, state);
  });

  pi.on("before_agent_start", async (event, ctx) => {
    pendingTreeRestore = undefined;
    if (activePrompt && !(await finalizePrompt(ctx))) return;
    awaitingInitialUserMessage = await beginPrompt(ctx, event.prompt);
  });

  pi.on("message_end", async (event, ctx) => {
    if (!isRecord(event.message)) return;

    if (event.message.role !== "user") return;
    const prompt = messageText(event.message);

    if (awaitingInitialUserMessage) {
      awaitingInitialUserMessage = false;
      if (activePrompt && prompt.trim() && prompt !== activePrompt.prompt) {
        activePrompt.prompt = prompt;
        await runJj(
          ["describe", "--message", promptDescription(prompt)],
          activePrompt.repoRoot,
        );
      }
      return;
    }

    // Steering and queued follow-up messages can arrive inside one agent run,
    // without another before_agent_start event. They are still commit boundaries.
    if (activePrompt && !(await finalizePrompt(ctx))) return;
    await beginPrompt(ctx, prompt);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    awaitingInitialUserMessage = false;
    await finalizePrompt(ctx);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    awaitingInitialUserMessage = false;
    pendingTreeRestore = undefined;
    await finalizePrompt(ctx);
  });

  pi.on("session_before_switch", async (_event, ctx) => {
    pendingTreeRestore = undefined;
    const state = resolveState(ctx);
    if (!state.enabled) return;

    try {
      if (activePrompt && !(await finalizePrompt(ctx))) return { cancel: true };
      await ensureCanLeaveState(ctx, resolveState(ctx));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      reportError(ctx, message);
      return { cancel: true };
    }
  });

  pi.on("session_before_tree", async (event, ctx) => {
    pendingTreeRestore = undefined;
    const leafId = targetLeafId(ctx, event.preparation.targetId);
    let currentState = resolveState(ctx);
    let targetState = resolveState(ctx, leafId);
    if (!currentState.enabled && !targetState.enabled) return;

    try {
      if (activePrompt && !(await finalizePrompt(ctx))) return { cancel: true };
      currentState = resolveState(ctx);
      targetState = resolveState(ctx, leafId);

      if (currentState.enabled) await ensureCanLeaveState(ctx, currentState);
      if (!targetState.enabled) return;

      const repoRoot = await ensureRepo(ctx, targetState);
      const workingCopy = await readWorkingCopy(repoRoot);

      const keepFilesState = checkpointForWorkingCopy(repoRoot, workingCopy, currentState);
      const targetCommitId = targetState.headCommitId
        ? await resolveLiveHeadCommitId(repoRoot, targetState)
        : targetState.baseParentCommitIds.length === 1
          ? targetState.baseParentCommitIds[0]
          : undefined;

      if (!targetCommitId) {
        pendingTreeRestore = {
          restoreFiles: false,
          repoRoot,
          targetState,
          keepFilesState,
        };
        return;
      }

      const { changeId, preview } = await treeRestorePreview(repoRoot, targetCommitId);
      let restoreFiles = false;
      if (ctx.hasUI) {
        const restoreOption = `also restore files to rev: ${changeId}`;
        const keepOption = "only reset the conversation (keep files unchanged)";
        const choice = await ctx.ui.select(`Restore this tree point?\n\n${preview}`, [
          restoreOption,
          keepOption,
        ]);
        if (!choice) return { cancel: true };
        restoreFiles = choice === restoreOption;
      }

      pendingTreeRestore = {
        restoreFiles,
        repoRoot,
        targetState,
        targetCommitId,
        keepFilesState,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      reportError(ctx, message);
      return { cancel: true };
    }
  });

  pi.on("session_tree", async (_event, ctx) => {
    const restorePlan = pendingTreeRestore;
    pendingTreeRestore = undefined;
    activePrompt = undefined;
    awaitingInitialUserMessage = false;
    statusError = undefined;
    const state = resolveState(ctx);

    if (state.enabled) {
      try {
        let checkpoint: EnabledStateData;
        if (restorePlan?.restoreFiles && restorePlan.targetCommitId) {
          if (restorePlan.targetState.headCommitId) {
            // This is the only file-restoring operation for a mapped Pi commit.
            await runJj(["edit", restorePlan.targetCommitId], restorePlan.repoRoot);
            const restored = await readWorkingCopy(restorePlan.repoRoot);
            if (restored.commitId !== restorePlan.targetCommitId) {
              throw new Error("jj edit did not land on the selected Pi revision");
            }
            checkpoint = {
              version: DATA_VERSION,
              enabled: true,
              repoRoot: restorePlan.repoRoot,
              baseParents: restorePlan.targetState.baseParentCommitIds,
              headCommitId: restorePlan.targetCommitId,
              headChangeId: restored.changeId,
              allowEmptyChild: false,
            };
          } else {
            await runJj(
              ["new", ...restorePlan.targetState.baseParentCommitIds],
              restorePlan.repoRoot,
            );
            const restored = await readWorkingCopy(restorePlan.repoRoot);
            if (
              !restored.empty ||
              restored.described ||
              !sameCommitIds(
                restored.parentCommitIds,
                restorePlan.targetState.baseParentCommitIds,
              )
            ) {
              throw new Error("jj new did not land on the selected Pi base revision");
            }
            checkpoint = {
              version: DATA_VERSION,
              enabled: true,
              repoRoot: restorePlan.repoRoot,
              baseParents: restorePlan.targetState.baseParentCommitIds,
              allowEmptyChild: false,
            };
          }
        } else if (restorePlan) {
          // The user explicitly chose conversation-only navigation. Do not run a
          // mutating jj command; make the current files the checkpoint instead.
          checkpoint = restorePlan.keepFilesState;
        } else {
          // Never restore files from /tree without the confirmation hook.
          const repoRoot = await ensureRepo(ctx, state);
          const workingCopy = await readWorkingCopy(repoRoot);
          checkpoint = checkpointForWorkingCopy(repoRoot, workingCopy, state);
        }
        pi.appendEntry(STATE_ENTRY, checkpoint);
      } catch (error) {
        reportError(ctx, error instanceof Error ? error.message : String(error));
        return;
      }
    }
    showStatus(ctx);
  });

  pi.on("session_before_fork", async (event, ctx) => {
    pendingTreeRestore = undefined;
    const selected = ctx.sessionManager.getEntry(event.entryId);
    const leafId =
      event.position === "before" &&
      selected?.type === "message" &&
      selected.message.role === "user"
        ? selected.parentId
        : event.entryId;
    const currentState = resolveState(ctx);
    const targetState = resolveState(ctx, leafId);
    if (!currentState.enabled && !targetState.enabled) return;

    try {
      if (activePrompt && !(await finalizePrompt(ctx))) return { cancel: true };
      if (currentState.enabled) await ensureCanLeaveState(ctx, resolveState(ctx));
      else if (targetState.enabled) await ensureRepo(ctx, targetState);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      reportError(ctx, message);
      return { cancel: true };
    }
  });
}
