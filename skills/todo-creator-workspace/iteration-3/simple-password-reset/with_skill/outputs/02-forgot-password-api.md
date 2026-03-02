# Forgot Password API Endpoints + Email Sending

리셋 요청을 받아 이메일을 발송하고, 토큰으로 비밀번호를 변경하는 API 엔드포인트를 구현합니다. 이메일 주소 존재 여부를 응답에 노출하지 않아야 합니다(보안상 항상 동일한 응답).

- [ ] Implement `POST /api/auth/forgot-password` endpoint in `src/app/api/auth/forgot-password/route.ts` (or equivalent router file):
  - Accept `{ email: string }`, validate with Zod
  - Look up user by email — if not found, return `200 OK` with generic message (do NOT reveal whether email exists)
  - If found: call `createResetToken(userId)`, send reset email, return `200 OK`
- [ ] Implement `POST /api/auth/reset-password` endpoint in `src/app/api/auth/reset-password/route.ts`:
  - Accept `{ token: string, newPassword: string }`, validate with Zod (password min 8 chars)
  - Call `validateResetToken(token)` — return `400` with `"토큰이 유효하지 않거나 만료되었습니다."` if invalid
  - Hash new password, update user record, call `consumeResetToken(token)`, return `200 OK`
- [ ] Create email sending utility in `src/lib/email/send-reset-email.ts`:
  - Accepts `{ to: string, resetUrl: string }`
  - Constructs reset URL as `{NEXT_PUBLIC_APP_URL}/reset-password?token={plainToken}`
  - Send via existing email provider (check project for nodemailer / Resend / SendGrid setup)
  - Subject: `"비밀번호 재설정 안내"`, body includes link and 1시간 만료 안내
- [ ] Add `RESET_PASSWORD_TOKEN_SECRET` (if using HMAC) or confirm `crypto.randomBytes` approach to `.env.example`
- [ ] Write tests in `src/app/api/auth/__tests__/forgot-password.test.ts`: (a) returns 200 for unknown email without leaking existence, (b) sends email for known email, (c) reset-password succeeds with valid token, (d) reset-password returns 400 for expired token, (e) token cannot be reused