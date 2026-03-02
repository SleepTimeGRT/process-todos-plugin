# Update Prisma Schema for User Profile Fields

The profile page requires that the User model stores a display nickname and an avatar image URL. These fields must be added to the Prisma schema and migrated before the API routes or UI can be built, since all subsequent work depends on the shape of the database record.

- [ ] Open `prisma/schema.prisma` and locate the `User` model. Add a `nickname` field of type `String?` (nullable, so existing users are not broken) and an `avatarUrl` field of type `String?` (nullable, stores the path or URL to the uploaded image).
- [ ] Run `npx prisma migrate dev --name add-user-profile-fields` to generate and apply the migration. Commit the generated migration file under `prisma/migrations/`.
- [ ] Run `npx prisma generate` to regenerate the Prisma client so TypeScript picks up the new fields.
- [ ] Update any existing seed file (`prisma/seed.ts` if it exists) to include sample values for `nickname` and `avatarUrl` on test users so local development has realistic data.
- [ ] Verify the migration succeeded by opening Prisma Studio (`npx prisma studio`) and confirming the `nickname` and `avatarUrl` columns appear on the `User` table.
