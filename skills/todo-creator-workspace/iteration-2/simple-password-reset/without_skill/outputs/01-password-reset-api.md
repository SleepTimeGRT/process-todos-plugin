# Password Reset API Endpoint

Implement the backend API for the password reset flow. This includes generating a secure reset token, persisting it to the database via Prisma, and sending a reset link to the user's email address.

- [ ] Add a `passwordResetToken` and `passwordResetTokenExpiry` field to the `User` model in `prisma/schema.prisma`
- [ ] Run `npx prisma migrate dev` to apply the schema changes
- [ ] Install an email sending library (e.g., `nodemailer` or `resend`) if not already present
- [ ] Create `app/api/auth/forgot-password/route.ts` with a `POST` handler
- [ ] In the handler, validate that the request body contains a non-empty `email` field
- [ ] Query the database with Prisma to find the user by email; if no user is found, return a 200 response without revealing whether the email exists
- [ ] Generate a cryptographically secure random token using `crypto.randomBytes`
- [ ] Store the hashed token and an expiry timestamp (e.g., 1 hour from now) on the user record via Prisma `update`
- [ ] Send an email to the user containing a reset link in the format `{NEXT_PUBLIC_BASE_URL}/auth/reset-password?token={rawToken}`
- [ ] Return a generic 200 JSON response such as `{ message: "If that email exists, a reset link has been sent." }`
- [ ] Add error handling and return a 500 response on unexpected failures
