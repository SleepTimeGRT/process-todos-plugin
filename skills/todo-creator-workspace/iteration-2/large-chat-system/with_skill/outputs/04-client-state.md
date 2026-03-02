# Implement Client-Side State Layer for Chat (Store + WebSocket Hook)

The client state layer decouples data management from the UI. It consists of a Zustand store that holds conversation and message state, a custom React hook that manages the WebSocket lifecycle, and React Query integration for initial data fetching and cache invalidation. This layer is independently testable and can be developed before the UI components exist. Architectural assumption: Zustand is used (not Redux) for local chat state because the store shape is simple and co-located mutation is ergonomic; React Query handles server-state hydration and refetching on reconnect.

- [ ] Install dependencies if not present: `zustand`, `@tanstack/react-query`, `socket.io-client`
- [ ] Define the Zustand store in `src/stores/chatStore.ts`:
  - State shape:
    ```ts
    interface ChatStore {
      conversations: Record<string, ConversationWithMembers>;
      messages: Record<string, MessageWithSender[]>; // keyed by conversationId
      nextCursors: Record<string, string | null>;
      activeConversationId: string | null;
      unreadCounts: Record<string, number>;
    }
    ```
  - Actions: `setConversations`, `setActiveConversation`, `appendMessage`, `prependMessages` (for history pagination), `updateReadReceipt`, `incrementUnread`, `clearUnread`
  - `appendMessage` must de-duplicate by `id` to handle the case where the sender receives their own message back from the WebSocket after an optimistic insert
- [ ] Create `src/hooks/useChat.ts` — a hook that:
  - Initializes and memoizes the `socket.io-client` connection (connects on mount, disconnects on unmount)
  - Joins/leaves rooms via `chat:join` / `chat:leave` when `activeConversationId` changes
  - Registers listeners for `chat:message` → calls `appendMessage` on the store
  - Registers listeners for `chat:read_receipt` → calls `updateReadReceipt` on the store
  - Registers listeners for `chat:error` → surfaces errors via a toast notification (assume `sonner` or `react-hot-toast`)
  - Exposes `sendMessage(content: string)` — emits `chat:send` with optimistic insert (append a provisional message with a temp ID, then reconcile when the server echoes back)
  - Exposes `markAsRead(messageId: string)` — emits `chat:read` and calls `clearUnread` on the store
  - Returns `{ sendMessage, markAsRead, isConnected: boolean }`
- [ ] Create `src/hooks/useChatHistory.ts` using React Query:
  - `useQuery` for initial message fetch (`GET /api/chat/conversations/[id]/messages`)
  - `useInfiniteQuery` for pagination (load older messages using cursor from store)
  - On success, call `prependMessages` on the Zustand store
  - Set `staleTime: Infinity` (WebSocket keeps data fresh; refetch only on window focus after disconnect)
- [ ] Create `src/hooks/useConversations.ts` using React Query:
  - `useQuery` for conversation list (`GET /api/chat/conversations`)
  - On success, call `setConversations` on the store
  - Expose `createConversation(payload)` mutation that calls `POST /api/chat/conversations` and invalidates the query on success
- [ ] Write tests in `src/__tests__/chat/useChat.test.ts` using `renderHook` from `@testing-library/react` and `socket.io-mock`:
  - Receiving `chat:message` event appends the message to the correct conversation in the store
  - Calling `sendMessage` optimistically inserts a provisional message before the server response
  - Receiving the server echo of the sent message de-duplicates correctly (only one message in store)
  - `markAsRead` emits `chat:read` with the correct `conversationId` and `messageId`
  - When `activeConversationId` changes from A to B, hook leaves room A and joins room B
- [ ] Write tests in `src/__tests__/chat/useChatHistory.test.ts`:
  - Initial load populates the Zustand store via `prependMessages`
  - Fetching next page appends older messages without duplicating the cursor message
