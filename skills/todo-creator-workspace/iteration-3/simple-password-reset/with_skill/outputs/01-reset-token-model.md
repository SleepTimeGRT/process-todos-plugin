# Create Password Reset Token Data Model

비밀번호 찾기 기능의 기반이 되는 토큰 저장소를 설계합니다. 이메일로 발송된 리셋 링크의 유효성 검증에 사용됩니다. 토큰은 단일 사용(소진형)이며 만료 시간을 가져야 합니다.

- [ ] Define `PasswordResetToken` model/schema with fields: `id`, `userId`, `token` (hashed), `expiresAt`, `usedAt`, `createdAt`
- [ ] Create database migration (or update schema file) for the `password_reset_tokens` table
- [ ] Implement `createResetToken(userId: string): Promise<string>` in `src/lib/auth/reset-token.ts` — generates a cryptographically random token, hashes it before storage (store hash, return plain), sets `expiresAt` to 1 hour from now
- [ ] Implement `validateResetToken(token: string): Promise<{ valid: boolean; userId?: string }>` — looks up by hashed token, checks not expired, checks not already used
- [ ] Implement `consumeResetToken(token: string): Promise<void>` — marks `usedAt` to prevent reuse
- [ ] Write tests in `src/lib/auth/__tests__/reset-token.test.ts`: (a) creates valid token, (b) returns invalid for expired token (mock date), (c) returns invalid for already-used token, (d) returns invalid for unknown token