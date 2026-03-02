# Backend: 프로필 사진 업로드 API

`multipart/form-data` 방식의 파일 업로드 엔드포인트를 구현합니다. 이미지 검증·리사이징 후 저장하고, 저장된 URL을 사용자 레코드에 반영합니다.

> Assumption: 파일 저장은 로컬 `public/uploads/avatars/`에 저장 (외부 스토리지 서비스 미사용). 이미지 처리는 `sharp` 라이브러리 사용. 파일명은 UUID로 생성해 충돌 방지.

- [ ] 의존성 설치: `npm install multer sharp uuid` + `npm install -D @types/multer @types/uuid`
- [ ] `src/lib/upload.ts`에 multer 설정 구현: 허용 MIME 타입(`image/jpeg`, `image/png`, `image/webp`), 최대 파일 크기 5MB, 메모리 스토리지(`memoryStorage`) 사용
- [ ] `src/lib/avatarProcessor.ts`에 이미지 처리 함수 구현: sharp로 256×256 리사이징 + `cover` 크롭, WebP 변환, `public/uploads/avatars/{uuid}.webp`에 저장, 저장 경로 반환
- [ ] `POST /api/users/me/avatar` 엔드포인트 구현 (`src/routes/users.ts`에 추가): `requireAuth` + multer 미들웨어 체인 → `avatarProcessor` 호출 → DB `avatarUrl` 업데이트 → `{ avatarUrl: "/uploads/avatars/{uuid}.webp" }` 반환
- [ ] 기존 아바타 파일 정리 로직: 새 아바타 업로드 성공 후 이전 파일이 `public/uploads/avatars/`에 존재하면 `fs.unlink`로 삭제
- [ ] Express에서 `public/` 디렉터리 정적 파일 서빙 설정 확인 (`app.use(express.static('public'))`)
- [ ] `src/routes/__tests__/avatar.test.ts` 작성: (a) 유효한 JPEG 업로드 성공 및 `avatarUrl` 반환, (b) 5MB 초과 파일 거부 (413), (c) PDF 등 허용되지 않는 형식 거부 (400), (d) 인증 없이 업로드 시도 시 401