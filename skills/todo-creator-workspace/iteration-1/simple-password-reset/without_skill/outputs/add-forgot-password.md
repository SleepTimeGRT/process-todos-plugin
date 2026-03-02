# Add Forgot Password Flow to Login Page

This feature adds a "비밀번호 찾기" (forgot password) link to the existing login page. Clicking the link navigates to a dedicated page with an email input form. Submitting the form calls an API route that sends a password reset link to the provided email address.

- [ ] Add a "비밀번호 찾기" anchor link below the login form in `src/app/login/page.tsx` that navigates to `/forgot-password`
- [ ] Create `src/app/forgot-password/page.tsx` with a form containing a single email input field and a submit button labeled "리셋 링크 보내기"
- [ ] Create `src/app/api/auth/forgot-password/route.ts` implementing a POST handler that accepts `{ email: string }`, validates the email is non-empty, generates a password reset token (use `crypto.randomUUID()` or similar), and returns `{ message: string }` — for now, log the reset link to the console instead of actually sending an email
- [ ] Wire the forgot-password form in `src/app/forgot-password/page.tsx` to POST to `/api/auth/forgot-password`, show a success message ("이메일을 확인해주세요.") on success, and display an error message if the request fails
- [ ] Add a "로그인으로 돌아가기" link on the forgot-password page that navigates back to `/login`
