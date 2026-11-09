/** One usage window: which one, how much is used (0 to 100), when it resets. */
export type Window = { kind: string; percentUsed: number; resetsAt?: string }

/**
 * The prompt cache as the band last saw it: when the main thread last sent a
 * request (clock milliseconds), how much context the next request re-sends,
 * the model's context window, and the model.
 */
export type CacheFacts = { lastAt: number; tokens: number; window: number; model: string | null }

/** Whether the cache card is open, remembered only for the state it was set in. */
export type Fold = { mode: 'warm' | 'cold'; open: boolean }

/**
 * Where the main agent works: its folder relative to the checkout root, the git
 * branch, and the linked worktree's name (null in the main checkout or outside git).
 */
export type Where = { folder: string; branch: string | null; worktree: string | null }

declare module 'claude-code' {
  interface PluginState {
    /** `effort`: the level the main thread's last request asked for; null before one, or for a model without effort. */
    /** `spent`: US dollars this session has cost, as /cost totals it; null where the host keeps no ledger. */
    'ribbon-ctx': { windows: Window[]; cache: CacheFacts | null; fold: Fold | null; spent: number | null; where: Where | null; effort: string | null }
  }
}
