# Build the User Profile Page UI

This todo assembles the profile page from focused form components, each consuming hooks from todo 03. The page lives at `/profile` and is protected (redirects to `/login` if unauthenticated). Assumption: the project uses Tailwind CSS for styling, `react-hook-form` for form management, and `shadcn/ui` for base components (Button, Input, Avatar). Error messages from the API are mapped to human-readable Korean strings since the product targets Korean users.

- [ ] Define component prop interfaces in `components/profile/types.ts`:
  ```ts
  export interface AvatarUploadProps {
    currentAvatarUrl: string | null;
    onUploadSuccess: (newUrl: string) => void;
  }
  export interface NicknameFormProps {
    currentNickname: string | null;
  }
  export interface PasswordFormProps {}
  ```
- [ ] Create `components/profile/AvatarUpload.tsx`:
  - Display the current avatar using `<Image>` (Next.js) with a fallback icon when `avatarUrl` is null
  - Provide a hidden `<input type="file" accept="image/jpeg,image/png,image/webp">` triggered by clicking the avatar
  - Show a circular progress spinner overlay while `isUploading` is true
  - On error with code `INVALID_FILE`, display: "5MB 이하의 JPG, PNG, WebP 이미지만 업로드할 수 있습니다."
- [ ] Create `components/profile/NicknameForm.tsx`:
  - A `react-hook-form` form with a single `nickname` text input and a submit button
  - Show inline validation error "닉네임은 2자 이상 30자 이하여야 합니다." for out-of-range length
  - On success, show a toast notification: "닉네임이 변경되었습니다."
- [ ] Create `components/profile/PasswordForm.tsx`:
  - A `react-hook-form` form with `currentPassword`, `newPassword`, and `confirmNewPassword` fields (all `type="password"`)
  - Client-side validation: `newPassword` must be at least 8 characters; `confirmNewPassword` must match `newPassword`
  - On `ApiError` with code `INCORRECT_PASSWORD`, display inline field error: "현재 비밀번호가 올바르지 않습니다."
  - On success, reset the form and show a toast: "비밀번호가 변경되었습니다."
- [ ] Create the page at `app/profile/page.tsx` (or `pages/profile.tsx`):
  - Server-side: check session with `getServerSession`; redirect to `/login` if unauthenticated
  - Render a layout with three sections: avatar upload, nickname form, password form
  - Show a skeleton loader while `useProfileQuery` is loading
- [ ] Write tests in `tests/ui/ProfilePage.test.tsx` covering:
  - Unauthenticated users are redirected to `/login`
  - The page renders the user's current nickname and avatar after data loads
  - Submitting the nickname form with a valid value calls `useUpdateNicknameMutation` and shows the success toast
  - Submitting the password form with a mismatched `confirmNewPassword` shows a client-side validation error without making an API call
  - Submitting the password form with a wrong current password displays "현재 비밀번호가 올바르지 않습니다."
  - Clicking the avatar area and selecting a valid image triggers `useUploadAvatarMutation` and shows the spinner
