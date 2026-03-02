# Frontend: User Profile Page

Build the user profile page UI in Next.js (App Router). The page should display the user's current profile information and provide three interactive sections: profile photo upload, nickname change, and password change. Each section should communicate with its corresponding API route.

- [ ] Create the page file at `app/profile/page.tsx` as a server component that fetches the current user's session and profile data
- [ ] Redirect unauthenticated users to the login page using `redirect('/login')` if no session is found
- [ ] Create a client component `components/profile/AvatarUpload.tsx` that renders the current avatar image (using `next/image`) and a file input for uploading a new photo
- [ ] In `AvatarUpload.tsx`, on file selection, send a `POST` request to `/api/profile/avatar` using `FormData`, then update the displayed avatar on success
- [ ] Create a client component `components/profile/NicknameForm.tsx` with a controlled text input pre-filled with the user's current nickname and a submit button
- [ ] In `NicknameForm.tsx`, on form submission, send a `PATCH` request to `/api/profile/nickname` with the new nickname in the JSON body; show a success or error message based on the response
- [ ] Create a client component `components/profile/PasswordForm.tsx` with inputs for current password, new password, and confirm new password
- [ ] In `PasswordForm.tsx`, validate that `newPassword` and `confirmPassword` match on the client before submitting; send a `PATCH` request to `/api/profile/password` on valid submission; show success or error feedback
- [ ] Compose all three components inside `app/profile/page.tsx` in a clean layout with clear section headings
- [ ] Add loading and disabled states to all form submit buttons to prevent duplicate submissions
- [ ] Add the profile page link to the main navigation or user menu
