# 사용자 프로필 DB 스키마 업데이트

users 테이블에 프로필 기능에 필요한 컬럼을 추가한다. 이 스키마 변경은 이후 API 엔드포인트와 프론트엔드 작업의 기반이 되므로 가장 먼저 완료되어야 한다. avatar_url은 파일 저장소 경로(또는 외부 URL)를 저장하고, nickname은 사용자가 표시하는 이름으로 username과 별도로 관리한다.

- [ ] users 테이블에 `avatar_url VARCHAR(500) DEFAULT NULL` 컬럼 추가하는 마이그레이션 파일 작성 (예: `migrations/YYYYMMDD_add_user_profile_fields.sql`)
- [ ] users 테이블에 `nickname VARCHAR(50) DEFAULT NULL` 컬럼 추가 (동일 마이그레이션 파일에 포함)
- [ ] nickname에 고유성 제약 추가 여부 결정 — 고유하면 더 명확하지만 변경 시 충돌 처리 필요. 고유 인덱스 추가: `CREATE UNIQUE INDEX IF NOT EXISTS idx_users_nickname ON users(nickname)`
- [ ] User 모델(또는 타입 정의)에 `avatarUrl: string | null`, `nickname: string | null` 필드 추가 (예: `src/models/User.ts` 또는 `src/types/user.ts`)
- [ ] 파일 업로드 저장 위치 결정 및 문서화: 로컬 `public/uploads/avatars/` 디렉토리 사용을 기본으로 가정. 해당 디렉토리 생성 및 `.gitkeep` 추가
- [ ] 마이그레이션 실행 후 기존 users 레코드의 신규 컬럼이 NULL 상태임을 확인하는 seed/verify 스크립트 작성