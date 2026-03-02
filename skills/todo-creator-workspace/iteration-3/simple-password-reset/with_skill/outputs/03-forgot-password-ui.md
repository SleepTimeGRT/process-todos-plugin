# Forgot Password UI — Login Link + Request Form + Reset Form

로그인 페이지에 링크를 추가하고, 이메일 입력 페이지와 비밀번호 재설정 페이지를 구현합니다.

- [ ] In the login form component (`src/components/auth/LoginForm.tsx` or equivalent), add a `"비밀번호 찾기"` link below the password field — navigate to `/forgot-password`
- [ ] Create `/forgot-password` page at `src/app/forgot-password/page.tsx`:
  - Email input field with label `"가입 시 사용한 이메일"`
  - Submit button `"재설정 링크 보내기"`
  - On submit: POST to `/api/auth/forgot-password`, show success message `"이메일을 확인해 주세요. 재설정 링크를 보내드렸습니다."` regardless of whether email exists
  - Show inline error only for invalid email format (client-side validation)
  - Loading state on button during submission
- [ ] Create `/reset-password` page at `src/app/reset-password/page.tsx`:
  - Read `token` from URL query params
  - If no token present, show error `"유효하지 않은 링크입니다."` with link back to login
  - Two fields: `"새 비밀번호"` and `"새 비밀번호 확인"` — validate they match before submit
  - On submit: POST to `/api/auth/reset-password` with token + newPassword
  - On success: show `"비밀번호가 변경되었습니다."` and redirect to `/login` after 2 seconds
  - On API error (`400`): show `"토큰이 유효하지 않거나 만료되었습니다. 다시 시도해 주세요."` with link to `/forgot-password`
- [ ] Ensure both new pages are accessible without authentication (exclude from auth middleware/guards)
- [ ] Write component tests in `src/app/forgot-password/__tests__/page.test.tsx`: (a) renders email input, (b) shows success message after submit regardless of response, (c) shows format error for invalid email