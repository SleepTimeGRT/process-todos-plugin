# Build the Profile Page UI

This todo builds the user-facing profile page at `/profile` and the three self-contained form components it contains. The page fetches the current user's data on load and lets the user upload an avatar, update their nickname, and change their password — each section operates independently and shows inline success/error feedback. Assumes Tailwind CSS is available (standard for new Next.js projects); adjust class names if the project uses a different styling solution.

- [ ] Create the page file `src/app/profile/page.tsx` as a Next.js App Router page. It should:
  - Be a `"use client"` component (or use a server component wrapper that passes initial data as props — prefer `"use client"` for simplicity given the interactive forms).
  - On mount, fetch `GET /api/profile` to populate the initial state (`nickname`, `avatarUrl`).
  - Render a page layout with a heading "프로필 설정" and three sections: Avatar Upload, Nickname, Password.
  - Show a loading skeleton while the initial fetch is in progress.
  - Protect the route: if no session is found, redirect to `/login` (use the existing auth hook or `useSession` from `next-auth`, depending on what the project uses).
- [ ] Create `src/components/profile/AvatarUpload.tsx`. This component should:
  - Accept props: `currentAvatarUrl: string | null`, `onSuccess: (newUrl: string) => void`.
  - Display the current avatar in a circular `<img>` tag (100×100 px) with a fallback placeholder (e.g., a gray circle with the user's initial) if `currentAvatarUrl` is null.
  - Render a hidden `<input type="file" accept="image/jpeg,image/png,image/webp">` triggered by clicking an "사진 변경" button overlaid on the avatar.
  - On file selection, immediately show a local `URL.createObjectURL` preview so the user sees the new image before uploading.
  - On a separate "저장" button click, `POST` the file to `/api/profile/avatar` using `FormData`, show a spinner during upload, call `onSuccess` with the returned `avatarUrl` on success, and display an inline error message on failure.
  - Enforce the 5 MB size limit client-side before sending: show `{ error: '파일 크기는 5MB 이하여야 합니다.' }` if exceeded.
- [ ] Create `src/components/profile/NicknameForm.tsx`. This component should:
  - Accept props: `currentNickname: string | null`, `onSuccess: (newNickname: string) => void`.
  - Render a controlled `<input type="text">` pre-filled with `currentNickname`.
  - Validate inline (on blur and on submit): 2–30 characters, no leading/trailing whitespace — show a red helper text if invalid.
  - On submit, `PATCH /api/profile/nickname` with `{ nickname }`, disable the form during the request, show a green "저장되었습니다" message on success, and show the server error message (e.g., "이미 사용 중인 닉네임입니다.") on `409`.
  - Only enable the submit button when the value has changed from `currentNickname` and passes client-side validation.
- [ ] Create `src/components/profile/PasswordForm.tsx`. This component should:
  - Render three password inputs: "현재 비밀번호", "새 비밀번호", "새 비밀번호 확인".
  - Validate inline: new password must be 8+ characters with at least one uppercase letter and one number; confirmation must match new password. Show descriptive red helper text per field on failure.
  - On submit, `PATCH /api/profile/password` with `{ currentPassword, newPassword }`, disable the form during the request.
  - On success (`200`), show "비밀번호가 변경되었습니다." and clear all three fields.
  - On `401`, show "현재 비밀번호가 올바르지 않습니다." next to the current-password input.
  - On `400`, show the server's validation error message.
- [ ] Add a navigation link to the profile page from the site's main navigation or user dropdown menu (look for `src/components/Navbar.tsx`, `src/components/Header.tsx`, or similar — add a "프로필" link that points to `/profile`).
- [ ] Write a basic smoke test in `src/app/profile/page.test.tsx` (or `__tests__/profile.test.tsx`) using React Testing Library that:
  - Mocks `GET /api/profile` to return `{ nickname: 'testuser', avatarUrl: null }`.
  - Asserts the page renders the "프로필 설정" heading.
  - Asserts the nickname input is pre-filled with "testuser".
