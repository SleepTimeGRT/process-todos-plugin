# Implement Client-Side State and API Integration for Profile

This layer provides the data-fetching hooks and mutation functions that the profile UI components consume. It abstracts all `fetch` calls to the API routes defined in todo 02, and handles loading, error, and success states so the UI layer stays declarative. Assumption: the project uses React Query (`@tanstack/react-query`) for server state. Error codes returned by the API (e.g., `INCORRECT_PASSWORD`, `INVALID_FILE`) are surfaced as typed error objects so the UI can display appropriate messages.

- [ ] Define a typed API client helper in `lib/api/profile.ts` with the following functions:
  - `fetchProfile(): Promise<UserProfile>` — `GET /api/profile`
  - `updateNickname(nickname: string): Promise<UserProfile>` — `PATCH /api/profile`
  - `changePassword(payload: { currentPassword: string; newPassword: string }): Promise<void>` — `POST /api/profile/password`
  - `uploadAvatar(file: File): Promise<{ avatarUrl: string }>` — `POST /api/profile/avatar` with `FormData`
  - Each function throws a typed `ApiError` (with a `code` string field) on non-2xx responses
- [ ] Define the `ApiError` type in `types/errors.ts`:
  ```ts
  export class ApiError extends Error {
    constructor(public code: string, message: string) { super(message); }
  }
  ```
- [ ] Create `hooks/useProfile.ts` using React Query:
  - `useProfileQuery()` — wraps `fetchProfile`, query key `['profile']`
  - `useUpdateNicknameMutation()` — wraps `updateNickname`, invalidates `['profile']` on success
  - `useChangePasswordMutation()` — wraps `changePassword`
  - `useUploadAvatarMutation()` — wraps `uploadAvatar`, invalidates `['profile']` on success
- [ ] Ensure `useUploadAvatarMutation` tracks upload progress via `XMLHttpRequest` or exposes an `isUploading` boolean so the UI can show a progress indicator
- [ ] Write tests in `tests/hooks/useProfile.test.ts` covering:
  - `useProfileQuery` returns profile data on successful fetch and exposes `isLoading` during fetch
  - `useUpdateNicknameMutation` calls `PATCH /api/profile`, updates the React Query cache, and triggers a re-render with the new nickname
  - `useChangePasswordMutation` throws an `ApiError` with `code: "INCORRECT_PASSWORD"` when the API returns that error code
  - `useUploadAvatarMutation` sets `isUploading` to `true` while the request is in flight
