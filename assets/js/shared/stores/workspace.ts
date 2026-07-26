import { get, writable, type Readable } from "svelte/store";
import {
  createWorkspaceChannel,
  type WorkspaceChannel,
  type WorkspaceCloseError,
} from "./workspace_channel";
import type {
  WorkspaceChannelState,
  WorkspaceEntry,
  WorkspaceSessionDescriptor,
  WorkspaceState,
} from "~/shared/types";

interface WorkspaceOptions {
  discovery?: WorkspaceChannel | false;
}

export interface WorkspaceStore extends Readable<WorkspaceState> {
  compact(sessionId: string): void;
  close(sessionId: string): void;
  dispose(): void;
  focus(sessionId: string): void;
  reconcile(descriptors: WorkspaceSessionDescriptor[]): void;
}

export function createWorkspace(options: WorkspaceOptions = {}): WorkspaceStore {
  const discovery =
    options.discovery === false ? null : (options.discovery ?? createWorkspaceChannel());
  const state = writable<WorkspaceState>({ entries: [], status: "loading", error: null });
  let lastWorkspace: WorkspaceChannelState["value"] = null;

  const discoverySubscription = discovery?.subscribe(handleDiscovery) ?? null;

  function handleDiscovery(discoveryState: WorkspaceChannelState) {
    state.update((current) => ({
      ...current,
      status: discoveryState.status,
      error: discoveryState.error,
      entries: current.entries.map((entry) => ({
        ...entry,
        channelStatus: discoveryState.status,
      })),
    }));

    if (discoveryState.status === "stale") {
      return;
    }

    if (
      discoveryState.status !== "ready" ||
      !discoveryState.value ||
      discoveryState.value === lastWorkspace
    ) {
      return;
    }

    lastWorkspace = discoveryState.value;
    reconcileEntries(discoveryState.value.sessions);
  }

  function replaceEntry(sessionId: string, replace: (entry: WorkspaceEntry) => WorkspaceEntry) {
    state.update((current) => ({
      ...current,
      entries: current.entries.map((entry) => (entry.id === sessionId ? replace(entry) : entry)),
    }));
  }

  function focus(sessionId: string) {
    if (!get(state).entries.some((entry) => entry.id === sessionId)) return;

    state.update((current) => ({
      ...current,
      entries: current.entries.map((entry) => ({
        ...entry,
        mode: entry.id === sessionId ? "theater" : "compact",
      })),
    }));
  }

  function compact(sessionId: string) {
    replaceEntry(sessionId, (entry) => ({ ...entry, mode: "compact" }));
  }

  function close(sessionId: string) {
    if (!discovery || !get(state).entries.some((entry) => entry.id === sessionId)) return;

    replaceEntry(sessionId, (entry) => ({ ...entry, closing: true, closeError: null }));

    discovery
      .close(sessionId)
      .receive("ok", () => undefined)
      .receive("error", (error) => {
        setCloseError(sessionId, closeError(error));
      })
      .receive("timeout", () => {
        setCloseError(sessionId, "Closing the game timed out. Try again.");
      });
  }

  function setCloseError(sessionId: string, error: string) {
    replaceEntry(sessionId, (entry) => ({
      ...entry,
      closing: false,
      closeError: error,
    }));
  }

  function reconcile(descriptors: WorkspaceSessionDescriptor[]) {
    reconcileEntries(descriptors);
  }

  function reconcileEntries(descriptors: WorkspaceSessionDescriptor[]) {
    const current = get(state);
    const descriptorsById = new Map(descriptors.map((descriptor) => [descriptor.id, descriptor]));

    const retainedEntries = current.entries
      .filter((entry) => descriptorsById.has(entry.id))
      .map((entry) => {
        const descriptor = descriptorsById.get(entry.id);
        if (!descriptor) return entry;

        return {
          ...entry,
          slug: descriptor.slug,
          channelStatus: "ready" as const,
          module: descriptor.module,
          connection: descriptor.connection,
        };
      });
    const retainedIds = new Set(retainedEntries.map((entry) => entry.id));
    const additions: WorkspaceEntry[] = [];

    for (const descriptor of descriptors) {
      if (retainedIds.has(descriptor.id)) continue;

      additions.push({
        id: descriptor.id,
        slug: descriptor.slug,
        mode: retainedEntries.length === 0 && additions.length === 0 ? "theater" : "compact",
        channelStatus: "ready",
        closing: false,
        closeError: null,
        module: descriptor.module,
        connection: descriptor.connection,
      });
    }

    state.update((latest) => ({
      ...latest,
      entries: [...retainedEntries, ...additions],
    }));
  }

  function dispose() {
    discoverySubscription?.();
    discovery?.dispose();

    state.set({ entries: [], status: "loading", error: null });
  }

  return {
    subscribe: state.subscribe,
    compact,
    close,
    dispose,
    focus,
    reconcile,
  };
}

function closeError(error: WorkspaceCloseError) {
  return error.reason ?? "Unable to close the game. Try again.";
}
