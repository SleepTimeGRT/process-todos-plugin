# API Route: Change Password

Create a Next.js API route that allows an authenticated user to change their password. The current password must be verified before the new password is accepted, and the new password must be hashed before being stored.

- [ ] Ensure `bcryptjs` is installed: `npm install bcryptjs @types/bcryptjs`
- [ ] Create `app/api/profile/password/route.ts` with a `PATCH` handler
- [ ] Protect the route so only authenticated users can access it (check session via `getServerSession` or equivalent)
- [ ] Parse the JSON request body to extract `currentPassword` and `newPassword`
- [ ] Validate that both fields are present and that `newPassword` is at least 8 characters long
- [ ] Fetch the current user's `passwordHash` from the database using `prisma.user.findUnique`
- [ ] Use `bcrypt.compare(currentPassword, user.passwordHash)` to verify the current password; return `401` if it does not match
- [ ] Hash the new password using `bcrypt.hash(newPassword, 12)`
- [ ] Update the user record using `prisma.user.update` with the new `passwordHash`
- [ ] Return a `200` success response with no sensitive data, or an appropriate error response on failure
