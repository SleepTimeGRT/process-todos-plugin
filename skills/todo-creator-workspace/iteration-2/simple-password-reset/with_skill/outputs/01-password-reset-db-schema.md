# Add PasswordResetToken DB Schema and Migration

This todo establishes the data layer for the "비밀번호 찾기" (forgot password) feature. The `PasswordResetToken` table is the foundation that the API routes in the next todo depend on — getting the schema right first prevents rework downstream. Assuming Prisma ORM with a PostgreSQL (or compatible) database; the migration command uses `prisma migrate dev`.

- [ ] Add a `PasswordResetToken` model to `prisma/schema.prisma` with the following fields: `id String @id @default(cuid())`, `token String @unique`, `email String`, `expiresAt DateTime`, `usedAt DateTime?`, `createdAt DateTime @default(now())`. Index `email` for fast lookups when invalidating old tokens on re-request.
- [ ] Run `npx prisma migrate dev --name add-password-reset-token` to generate the SQL migration file under `prisma/migrations/`. Commit both the schema change and the generated migration file.
- [ ] Run `npx prisma generate` to regenerate the Prisma client so the new model is available in TypeScript. Verify the generated types include `PasswordResetToken` before moving to the API todo.
- [ ] Define a TypeScript type in `src/types/auth.ts` (create the file if it does not exist): `export type PasswordResetTokenRecord = { id: string; token: string; email: string; expiresAt: Date; usedAt: Date | null; createdAt: Date }`. This mirrors the Prisma model and is used in tests and utility functions.
- [ ] Write a Prisma-level smoke test in `src/lib/__tests__/password-reset-token-schema.test.ts` that (a) inserts a `PasswordResetToken` record and reads it back by `token`, verifying all fields persist correctly; (b) verifies that two records with the same `token` value throw a unique-constraint error.
