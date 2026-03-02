# Extend Prisma Schema for User Profile

The user profile page requires storing additional fields per user: a profile picture URL and a nickname. These fields are added to the existing `User` model in Prisma. Assumption: the project already has a `User` model with `id`, `email`, and `password` (hashed) fields. Profile images will be stored externally (e.g., S3 or Cloudinary) and only the URL is persisted in the database.

- [ ] In `prisma/schema.prisma`, add `avatarUrl String?` and `nickname String?` fields to the `User` model
- [ ] Define a TypeScript type in `types/user.ts` for the public user profile shape:
  ```ts
  export interface UserProfile {
    id: string;
    email: string;
    nickname: string | null;
    avatarUrl: string | null;
  }
  ```
- [ ] Create and run a Prisma migration: `npx prisma migrate dev --name add_user_profile_fields`
- [ ] Verify `npx prisma generate` runs without errors and the Prisma client reflects the new fields
- [ ] Update any existing seed file (`prisma/seed.ts`) to include optional `nickname` and `avatarUrl` values for test users
- [ ] Write tests in `tests/db/user-profile-schema.test.ts` covering:
  - A new user can be created with `nickname` and `avatarUrl` as `null` (default)
  - A user's `nickname` and `avatarUrl` can be updated and persisted correctly
