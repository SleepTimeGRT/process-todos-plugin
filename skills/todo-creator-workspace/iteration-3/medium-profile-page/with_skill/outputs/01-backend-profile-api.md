# Backend: User Profile Read & Nickname Update API

사용자 프로필 조회 및 닉네임 변경 API를 구현합니다. 이 엔드포인트들은 프론트엔드 프로필 페이지의 기반이 되며, 이후 아바타 업로드·비밀번호 변경 API가 동일한 auth 미들웨어와 사용자 타입을 공유합니다.

> Assumption: JWT 기반 인증, Express + TypeScript 백엔드, ORM은 Prisma 사용 가정. DB 스키마에 `users` 테이블이 이미 존재하나 `nickname`, `avatarUrl` 컬럼은 이번 작업에서 추가.

- [ ] `prisma/schema.prisma`의 `User` 모델에 `nickname String?`과 `avatarUrl String?` 필드 추가 후 `npx prisma migrate dev --name add-user-profile-fields` 실행
- [ ] `src/types/user.ts`에 공유 타입 정의: `UserProfile { id, email, nickname, avatarUrl, createdAt }` 인터페이스와 `UpdateNicknameRequest { nickname: string }` 타입
- [ ] `src/middleware/auth.ts`에 `requireAuth` 미들웨어 구현 (없을 경우): Authorization 헤더에서 JWT 파싱 → `req.user`에 `{ id, email }` 주입, 실패 시 401 반환
- [ ] `GET /api/users/me` 엔드포인트 구현 (`src/routes/users.ts`): `requireAuth` 적용 후 DB에서 사용자 조회, `UserProfile` 형태로 응답 (password 해시 필드 제외)
- [ ] `PATCH /api/users/me/nickname` 엔드포인트 구현: 요청 바디 `{ nickname }` 검증 (2~20자, 특수문자 제한), DB 업데이트 후 업데이트된 `UserProfile` 반환
- [ ] 닉네임 중복 검사 로직 추가: 동일 닉네임 존재 시 409 Conflict + `{ error: "이미 사용 중인 닉네임입니다." }` 반환
- [ ] `src/routes/__tests__/users.test.ts` 작성: (a) 인증된 사용자가 프로필 조회 성공, (b) 인증 토큰 없을 때 401 반환, (c) 닉네임 변경 성공, (d) 중복 닉네임으로 409 반환, (e) 20자 초과 닉네임으로 400 반환