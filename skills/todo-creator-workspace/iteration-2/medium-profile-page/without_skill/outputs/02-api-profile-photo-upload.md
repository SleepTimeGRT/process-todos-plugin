# API Route: Profile Photo Upload

Create a Next.js API route that handles profile photo uploads. The uploaded file should be stored (e.g., on the local filesystem under `public/uploads` or a cloud storage service), and the resulting URL should be persisted to the `avatarUrl` field on the `User` record via Prisma.

- [ ] Install `formidable` (or use the built-in Next.js body parser disabled config) to handle multipart form data: `npm install formidable @types/formidable`
- [ ] Create `app/api/profile/avatar/route.ts` (App Router) with a `POST` handler
- [ ] Disable the default body parser for this route by exporting the appropriate route segment config
- [ ] Parse the incoming multipart request to extract the uploaded image file
- [ ] Validate file type (allow only `image/jpeg`, `image/png`, `image/webp`) and enforce a max file size of 5 MB
- [ ] Save the file to `public/uploads/avatars/` with a unique filename (e.g., `{userId}-{timestamp}.{ext}`)
- [ ] Update the authenticated user's `avatarUrl` field in the database using `prisma.user.update`
- [ ] Return a JSON response with the new `avatarUrl` on success, or an appropriate error response on failure
- [ ] Protect the route so that only authenticated users can upload (check session via `getServerSession` or equivalent auth utility)
