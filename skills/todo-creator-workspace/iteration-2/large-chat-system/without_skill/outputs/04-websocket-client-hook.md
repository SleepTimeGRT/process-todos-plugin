# WebSocket Client Hook

Build a React hook that manages the client-side WebSocket connection. The hook handles connection lifecycle, automatic reconnection with exponential backoff, and exposes a typed event API for the rest of the UI to consume.

- [ ] Create `hooks/use-chat-socket.ts` that opens a `WebSocket` connection to the server on mount and closes it on unmount
- [ ] Read the WebSocket URL from `NEXT_PUBLIC_WS_URL` environment variable with a fallback to `ws://localhost:3000`
- [ ] Implement exponential backoff reconnection: on `close` or `error`, wait `min(1000 * 2^attempt, 30000)` ms before reconnecting; reset attempt counter on successful `open`
- [ ] Define a `ChatEvent` discriminated union type covering all server-sent event shapes: `message_received`, `read_update`, `member_joined`, `member_left`, `connected`, `error`
- [ ] Accept an `onEvent: (event: ChatEvent) => void` callback parameter and call it inside the `message` handler after `JSON.parse`
- [ ] Expose a `send(payload: object) => void` helper that serializes to JSON and calls `socket.send`; buffer outgoing messages while the socket is not yet open
- [ ] Expose `status: 'connecting' | 'open' | 'closed' | 'error'` as part of the hook return value
- [ ] On initial open, send a `join_room` event for each room ID passed via a `roomIds: string[]` parameter so the server registers the client in those rooms
- [ ] Wrap the hook with `useCallback` and `useRef` to avoid creating new WebSocket instances on re-renders
