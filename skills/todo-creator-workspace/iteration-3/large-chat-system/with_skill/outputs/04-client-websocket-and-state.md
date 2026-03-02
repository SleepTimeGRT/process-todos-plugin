# Implement Client-Side WebSocket Connection and Chat State

This layer manages the WebSocket lifecycle on the frontend and provides the chat state that UI components consume. It's the bridge between the server's real-time events and React rendering. Depends on WS event types from todo #1.

Key decisions documented here: (1) Single WebSocket connection per user session — not per conversation. The server uses conversation rooms for routing. (2) Optimistic updates — messages appear instantly in the UI, then get confirmed/replaced when the server echoes back `message:new`. (3) Typing indicators live in ephemeral state (not persisted), auto-cleared after 4 seconds of no update.

- [ ] Create `src/lib/chat/ws-client.ts` — a class `ChatWebSocketClient`:
  - Constructor takes `token: string` and `onEvent: (event: WsServerEvent) => void`
  - `connect()`: creates `new WebSocket(wsUrl + '?token=' + token)`, sets up reconnection logic (exponential backoff, max 5 retries)
  - `send(event: WsClientEvent): void` — JSON-serializes and sends; queues if not yet connected
  - `disconnect()`: closes connection and clears reconnect timers
  - Exports a singleton factory: `getChatClient(token)` — returns existing or creates new instance
- [ ] Create `src/stores/chatStore.ts` using your project's state management library (Zustand/Redux/etc.):
  - State shape:
    ```ts
    interface ChatState {
      conversations: Map<string, Conversation>;       // conversationId → Conversation
      messages: Map<string, Message[]>;               // conversationId → messages (sorted ASC)
      activeConversationId: string | null;
      typingUsers: Map<string, Set<string>>;          // conversationId → Set of userIds typing
      onlineUsers: Set<string>;                       // Set of online userIds
      optimisticMessages: Map<string, Message>;       // tempId → optimistic message
      isConnected: boolean;
    }
    ```
  - Actions: `setActiveConversation`, `addMessage`, `addOptimisticMessage`, `confirmOptimisticMessage(tempId, realMessage)`, `deleteMessage`, `updateReadStatus`, `setTyping`, `setOnline/Offline`
  - `handleWsEvent(event: WsServerEvent)` — dispatches incoming events to appropriate actions
- [ ] Create `src/hooks/useChat.ts`:
  - Initializes `ChatWebSocketClient` on mount, connects with auth token, calls `store.handleWsEvent` on events
  - Exposes: `{ conversations, sendMessage, markRead, startTyping, stopTyping, isConnected }`
  - `sendMessage(conversationId, content)`: adds optimistic message with `tempId = crypto.randomUUID()`, sends WS event `message:send`; on receiving `message:new` with matching content+sender, replaces optimistic message
  - `markRead(conversationId)`: debounced 500ms — calls WS `read:mark` to avoid flooding on scroll
  - `startTyping/stopTyping`: calls WS events; `startTyping` sets a 2.5s local timer to auto-call `stopTyping`
- [ ] Create `src/hooks/useConversationMessages.ts`:
  - Takes `conversationId: string`
  - Fetches initial page via `GET /api/chat/conversations/:id/messages` on mount
  - Exposes `{ messages, loadMore, hasMore, isLoading }`
  - `loadMore()` uses the last message's ID as cursor for next page fetch
  - Merges fetched historical messages with live messages from store (dedup by id)
- [ ] Write tests in `src/hooks/__tests__/useChat.test.ts`: (a) optimistic message appears before server confirmation, (b) optimistic message is replaced (not duplicated) when server confirms, (c) markRead is debounced and not called more than once per 500ms window, (d) WebSocket reconnects after unexpected close