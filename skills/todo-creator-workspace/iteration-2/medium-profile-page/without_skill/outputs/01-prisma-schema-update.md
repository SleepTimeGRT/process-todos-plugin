# Update Prisma Schema for User Profile

The user profile feature requires extending the existing `User` model in Prisma to support a profile photo URL and nickname field. This schema change is the foundation that all other profile-related API routes and UI components depend on.

- [ ] Open `prisma/schema.prisma` and add `nickname String?` field to the `User` model
- [ ] Add `avatarUrl String?` field to the `User` model for storing the profile photo URL
- [ ] Run `npx prisma migrate dev --name add-user-profile-fields` to generate and apply the migration
- [ ] Run `npx prisma generate` to regenerate the Prisma client
- [ ] Verify the migration was applied successfully by inspecting the database schema
