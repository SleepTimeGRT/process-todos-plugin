# Backend: 비밀번호 변경 API

현재 비밀번호 확인 후 새 비밀번호로 변경하는 보안 엔드포인트를 구현합니다. 무차별 대입 공격 방지를 위한 rate limiting도 포함합니다.

> Assumption: bcrypt로 비밀번호 해싱, `express-rate-limit` 패키지 사용 가능 가정.

- [ ] `src/types/user.ts`에 `ChangePasswordRequest { currentPassword: string, newPassword: string }` 타입 추가
- [ ] 비밀번호 검증 규칙 함수 `validatePassword(password: string): { valid: boolean, message?: string }` 구현 (`src/lib/validation.ts`): 최소 8자, 영문+숫자 조합 필수
- [ ] `POST /api/users/me/password` 엔드포인트 구현 (`src/routes/users.ts`에 추가):
  1. `requireAuth` 미들웨어
  2. 요청 바디 `{ currentPassword, newPassword }` 검증
  3. DB에서 사용자 조회 (password 필드 포함)
  4. `bcrypt.compare`로 현재 비밀번호 검증 → 불일치 시 `401 { error: "현재 비밀번호가 올바르지 않습니다." }`
  5. `validatePassword`로 새 비밀번호 규칙 검사 → 위반 시 `400 { error: "..." }`
  6. `bcrypt.hash(newPassword, 12)`로 해싱 후 DB 업데이트
  7. `204 No Content` 반환
- [ ] 비밀번호 변경 엔드포인트에 rate limiting 적용: 동일 IP에서 15분에 5회 초과 시 429 반환 (`src/middleware/rateLimiter.ts`)
- [ ] `src/routes/__tests__/password.test.ts` 작성: (a) 올바른 현재 비밀번호로 변경 성공 (204), (b) 틀린 현재 비밀번호로 401, (c) 새 비밀번호가 규칙 미충족 시 400 + 한국어 에러 메시지, (d) 현재와 동일한 비밀번호로 변경 시도 시 400