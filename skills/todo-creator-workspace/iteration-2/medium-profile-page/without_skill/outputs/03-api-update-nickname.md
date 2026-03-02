# API Route: Update Nickname

Create a Next.js API route that allows an authenticated user to update their nickname. The new nickname should be validated and then persisted to the `nickname` field on the `User` record via Prisma.

- [ ] Create `app/api/profile/nickname/route.ts` with a `PATCH` handler
- [ ] Protect the route so only authenticated users can access it (check session via `getServerSession` or equivalent)
- [ ] Parse the JSON request body to extract the `nickname` field
- [ ] Validate that `nickname` is a non-empty string with a length between 2 and 30 characters
- [ ] Check for uniqueness of the nickname if the product requires it (`prisma.user.findFirst` where `nickname` equals the provided value and `id` is not the current user)
- [ ] Update the user record using `prisma.user.update` with the new `nickname`
- [ ] Return the updated user object (excluding sensitive fields like `passwordHash`) on success
- [ ] Return a `400` error response with a descriptive message if validation fails, and `409` if the nickname is already taken
