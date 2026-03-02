```01-reset-token-model.md
# Create Password Reset Token Data Model

비밀번호 찾기 기능의 기반이 되는 토큰 저장소를 설계합니다. 이메일로 발송된 리셋 링크의 유효성 검증에 사용됩니다. 토큰은 단일 사용(소진형)이며 만료 시간을 가져야 합니다.

- [ ] Define `PasswordResetToken` model/schema with fields: `id`, `userId`, `token` (hashed), `expiresAt`, `usedAt`, `createdAt`
- [ ] Create database migration (or update schema file) for the `password_reset_tokens` table
- [ ] Implement `createResetToken(userId: string): Promise<string>` in `src/lib/auth/reset-token.ts` — generates a cryptographically random token, hashes it before storage (store hash, return plain), sets `expiresAt` to 1 hour from now
- [ ] Implement `validateResetToken(token: string): Promise<{ valid: boolean; userId?: string }>` — looks up by hashed token, checks not expired, checks not already used
- [ ] Implement `consumeResetToken(token: string): Promise<void>` — marks `usedAt` to prevent reuse
- [ ] Write tests in `src/lib/auth/__tests__/reset-token.test.ts`: (a) creates valid token, (b) returns invalid for expired token (mock date), (c) returns invalid for already-used token, (d) returns invalid for unknown token
```

```02-forgot-password-api.md
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
```

```03-forgot-password-ui.md
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
```

---

**Created 3 todo files:**

| File | Items | Description |
|------|-------|-------------|
| `01-reset-token-model.md` | 6 | 리셋 토큰 데이터 모델 및 유틸리티 함수 |
| `02-forgot-password-api.md` | 5 | API 엔드포인트 + 이메일 발송 |
| `03-forgot-password-ui.md` | 4 | 로그인 링크 + 이메일 입력 페이지 + 비밀번호 재설정 페이지 |

**Key design decisions baked in:**
- 🔒 **보안**: 이메일 존재 여부를 API 응답에서 노출하지 않음 (항상 동일한 200 응답)
- 🔒 **토큰 해싱**: DB에는 토큰 원문이 아닌 해시값 저장
- ⏰ **1시간 만료 + 단일 사용**: `usedAt` 필드로 토큰 재사용 방지
- 번호 순서대로 처리하면 의존성 순서(모델 → API → UI)가 자연스럽게 보장됩니다.
