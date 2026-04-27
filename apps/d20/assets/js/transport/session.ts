import type {Channel} from "phoenix"
import type {Readable} from "svelte/store"
import {readable} from "svelte/store"
import socket from "../user_socket.js"

const CHANNEL_CLOSE_EVENT = "phx_close"
const CHANNEL_ERROR_EVENT = "phx_error"

type SessionStatus = "loading" | "ready" | "stale" | "failed"

type SessionError =
  | {kind: "connect_error"; cause: unknown}
  | {kind: "connect_timeout"; cause?: unknown}
  | {kind: "transport_error"; cause: unknown}
  | {kind: "transport_close"}

type SessionSpec = {
  value?: unknown
  connect?: {ok?: unknown; error?: unknown}
  events?: Record<string, unknown>
}

type ValueOf<TSpec extends SessionSpec> = TSpec extends {
  value: infer TValue
}
  ? TValue
  : unknown

type ConnectOkOf<TSpec extends SessionSpec> = TSpec extends {
  connect: {ok?: infer TOk}
}
  ? TOk
  : ValueOf<TSpec>

type ConnectErrorOf<TSpec extends SessionSpec> = TSpec extends {
  connect: {error?: infer TError}
}
  ? TError
  : unknown

type EventMapOf<TSpec extends SessionSpec> = TSpec extends {
  events: infer TEvents extends Record<string, unknown>
}
  ? TEvents
  : Record<never, never>

type RuntimeEventReducer<TValue> = (value: TValue | null, payload: unknown) => TValue

interface SessionState<TValue> {
  readonly value: TValue | null
  readonly status: SessionStatus
  readonly error: SessionError | null
}

type SessionConfig<TSpec extends SessionSpec> = {
  topic: string
  value?: ValueOf<TSpec> | null
  connect?: {
    ok?: (value: Readonly<ValueOf<TSpec>> | null, reply: ConnectOkOf<TSpec>) => ValueOf<TSpec>
    error?: (reply: ConnectErrorOf<TSpec>) => unknown
    timeout?: () => unknown
  }
  events?: Partial<{
    [K in keyof EventMapOf<TSpec>]: (
      value: Readonly<ValueOf<TSpec>> | null,
      payload: EventMapOf<TSpec>[K],
    ) => ValueOf<TSpec>
  }>
}

type SessionCore<TSpec extends SessionSpec> = Readable<SessionState<ValueOf<TSpec>>> & {
  push: Channel["push"]
}

type Session<TSpec extends SessionSpec> = SessionCore<TSpec> & {
  extend<TExtension extends object>(
    defineExtension: (session: SessionCore<TSpec>) => TExtension,
  ): Readable<SessionState<ValueOf<TSpec>>> & TExtension
}

export function createSession<TSpec extends SessionSpec>(config: SessionConfig<TSpec>): Session<TSpec> {
  let channel: Channel | null = null

  const initialState: SessionState<ValueOf<TSpec>> = {
    value: config.value ?? null,
    status: config.value == null ? "loading" : "ready",
    error: null,
  }

  const {subscribe} = readable<SessionState<ValueOf<TSpec>>>(initialState, (_set, update) => {
    channel = socket.channel(config.topic, {}) as Channel
    const cleanups: Array<() => void> = []

    const errorRef = channel.onError((reason) => {
      update((current) => ({
        ...current,
        status: current.value === null ? "failed" : "stale",
        error: {kind: "transport_error", cause: reason},
      }))
    })
    cleanups.push(() => channel?.off(CHANNEL_ERROR_EVENT, errorRef))

    const closeRef = channel.onClose(() => {
      update((current) => ({
        ...current,
        status: current.value === null ? "failed" : "stale",
        error: {kind: "transport_close"},
      }))
    })
    cleanups.push(() => channel?.off(CHANNEL_CLOSE_EVENT, closeRef))

    for (const [event, reducer] of Object.entries(config.events ?? {})) {
      const reduce = reducer as RuntimeEventReducer<ValueOf<TSpec>>
      const ref = channel.on(event, (payload) => {
        update((current) => ({
          value: reduce(current.value, payload),
          status: "ready",
          error: null,
        }))
      })
      cleanups.push(() => channel?.off(event, ref))
    }

    channel
      .join()
      .receive("ok", (response: ConnectOkOf<TSpec>) => {
        update((current) => ({
          value: config.connect?.ok
            ? config.connect.ok(current.value, response)
            : (response as ValueOf<TSpec>),
          status: "ready",
          error: null,
        }))
      })
      .receive("error", (response: ConnectErrorOf<TSpec>) => {
        update((current) => ({
          ...current,
          status: "failed",
          error: {
            kind: "connect_error",
            cause: config.connect?.error ? config.connect.error(response) : response,
          },
        }))
      })
      .receive("timeout", () => {
        update((current) => ({
          ...current,
          status: "failed",
          error: {
            kind: "connect_timeout",
            cause: config.connect?.timeout?.(),
          },
        }))
      })

    return () => {
      for (const cleanup of cleanups) cleanup()
      channel?.leave()
      channel = null
    }
  })

  const sessionCore: SessionCore<TSpec> = {
    subscribe,
    push: (event, payload, timeout) => {
      if (!channel) {
        throw new Error(`Cannot push "${event}" before joining "${config.topic}"`)
      }

      return channel.push(event, payload, timeout)
    },
  }

  return {
    ...sessionCore,
    extend(defineExtension) {
      return {...defineExtension(sessionCore), subscribe}
    },
  }
}
