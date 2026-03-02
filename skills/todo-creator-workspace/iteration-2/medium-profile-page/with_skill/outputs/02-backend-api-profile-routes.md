# Implement Backend API Routes for User Profile

These Next.js API routes expose the profile management operations to the frontend: fetching the current user's profile, updating the nickname, changing the password, and uploading a profile picture. Assumption: authentication is handled via NextAuth.js and `getServerSession` is used to identify the caller. Profile image uploads use multipart form data and are stored in an S3-compatible bucket; only the resulting URL is written to the database. Password hashing uses `bcryptjs`.

- [ ] Define Zod validation schemas in `lib/validations/profile.ts`:
  ```ts
  export const updateNicknameSchema = z.object({ nickname: z.string().min(2).max(30) });
  export const changePasswordSchema = z.object({
    currentPassword: z.string().min(8),
    newPassword: z.string().min(8),
  });
  ```
- [ ] Create `app/api/profile/route.ts` (or `pages/api/profile/index.ts`):
  - `GET` — return the authenticated user's `UserProfile` (id, email, nickname, avatarUrl)
  - `PATCH` — accept `{ nickname }`, validate with `updateNicknameSchema`, update via Prisma, return updated profile
  - Guard every handler with `getServerSession`; return `401` if unauthenticated
- [ ] Create `app/api/profile/password/route.ts`:
  - `POST` — accept `{ currentPassword, newPassword }`, validate with `changePasswordSchema`
  - Fetch user's hashed password from DB, verify `currentPassword` with `bcrypt.compare`
  - Hash `newPassword` with `bcrypt.hash(newPassword, 12)`, update via Prisma
  - Return `400` with `{ error: "INCORRECT_PASSWORD" }` if current password is wrong
- [ ] Create `app/api/profile/avatar/route.ts`:
  - `POST` — accept multipart form data with a file field named `avatar`
  - Validate file type (allow `image/jpeg`, `image/png`, `image/webp`) and max size (5 MB)
  - Upload to S3 (or Cloudinary) and obtain the public URL
  - Update `user.avatarUrl` in Prisma and return `{ avatarUrl }`
  - Return `400` with `{ error: "INVALID_FILE" }` for unsupported type or size violations
- [ ] Add an environment variable entry in `.env.example` for any storage credentials (e.g., `S3_BUCKET`, `S3_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- [ ] Write tests in `tests/api/profile.test.ts` covering:
  - `GET /api/profile` returns `401` when not authenticated
  - `GET /api/profile` returns the correct profile fields for an authenticated user
  - `PATCH /api/profile` with a valid nickname updates the DB and returns the new nickname
  - `PATCH /api/profile` with a nickname that is too short returns `400`
  - `POST /api/profile/password` with a wrong current password returns `400` with `INCORRECT_PASSWORD`
  - `POST /api/profile/password` with correct credentials updates the hashed password in the DB
  - `POST /api/profile/avatar` with an oversized file returns `400` with `INVALID_FILE`
  - `POST /api/profile/avatar` with a valid image returns the new `avatarUrl`
