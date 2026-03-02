# Implement Profile API Routes

These API routes power the three profile-editing features: avatar upload, nickname change, and password change. All routes sit under `src/app/api/profile/` and assume a session-based or JWT-based auth system is already in place (read the existing auth middleware/helper to wire in the current user). File uploads are stored in the `public/uploads/avatars/` directory and served as static assets — no external storage service is assumed.

- [ ] Create the directory `src/app/api/profile/` if it does not already exist.
- [ ] Create `src/app/api/profile/avatar/route.ts`. Implement a `POST` handler that:
  - Reads the authenticated user's session/token to get the current `userId` (use the same auth utility already used elsewhere in the project).
  - Parses the incoming `multipart/form-data` request using Next.js built-in `request.formData()`.
  - Validates the uploaded file: must be an image (`image/jpeg`, `image/png`, `image/webp`), max size 5 MB. Return a `400` JSON error if validation fails.
  - Generates a unique filename (e.g., `{userId}-{Date.now()}.{ext}`) and writes the file to `public/uploads/avatars/` using Node's `fs/promises`.
  - Updates the `User` record in the database via Prisma: `prisma.user.update({ where: { id: userId }, data: { avatarUrl: '/uploads/avatars/<filename>' } })`.
  - Returns `200` JSON with `{ avatarUrl: '/uploads/avatars/<filename>' }` on success.
  - Deletes the previous avatar file from disk if one existed (read `user.avatarUrl` before updating, then `fs.unlink` the old file if it resolves to a path inside `public/uploads/avatars/`).
- [ ] Create `src/app/api/profile/nickname/route.ts`. Implement a `PATCH` handler that:
  - Reads the authenticated `userId` from the session/token.
  - Parses the JSON body: `{ nickname: string }`.
  - Validates `nickname`: non-empty string, 2–30 characters, no leading/trailing whitespace. Return `400` with a descriptive error message on failure.
  - Checks uniqueness — query `prisma.user.findFirst({ where: { nickname, NOT: { id: userId } } })` and return `409` if another user already has that nickname.
  - Updates the user: `prisma.user.update({ where: { id: userId }, data: { nickname } })`.
  - Returns `200` JSON with `{ nickname }` on success.
- [ ] Create `src/app/api/profile/password/route.ts`. Implement a `PATCH` handler that:
  - Reads the authenticated `userId` from the session/token.
  - Parses the JSON body: `{ currentPassword: string, newPassword: string }`.
  - Fetches the user from the database and verifies `currentPassword` against the stored hash using the same hashing library used at sign-up (e.g., `bcryptjs` — check existing auth code).
  - Returns `401` with `{ error: 'Current password is incorrect' }` if verification fails.
  - Validates `newPassword`: minimum 8 characters, at least one uppercase letter and one number. Return `400` with a descriptive error on failure.
  - Hashes `newPassword` and updates: `prisma.user.update({ where: { id: userId }, data: { password: hashedPassword } })`.
  - Returns `200` JSON with `{ message: 'Password updated successfully' }`.
- [ ] Create `src/app/api/profile/route.ts`. Implement a `GET` handler that returns the current user's public profile fields (`id`, `email`, `nickname`, `avatarUrl`) so the profile page can populate its form on load.
- [ ] Ensure `public/uploads/avatars/` exists (create it with a `.gitkeep` so the directory is committed but its contents are gitignored — add `public/uploads/` to `.gitignore`).
- [ ] Add TypeScript types in `src/types/profile.ts` (or the project's existing types directory): `ProfileData`, `UpdateNicknameRequest`, `UpdatePasswordRequest`, `UpdateNicknameResponse`, `UpdatePasswordResponse`, `AvatarUploadResponse`.
