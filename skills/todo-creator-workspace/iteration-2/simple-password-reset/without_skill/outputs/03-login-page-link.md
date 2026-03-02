# Add Forgot Password Link to Login Page

Update the existing login page to include a "Forgot Password?" link that navigates the user to the forgot password page.

- [ ] Open the existing login page component (likely `app/auth/login/page.tsx` or similar)
- [ ] Import `Link` from `next/link` if not already imported
- [ ] Add a `<Link href="/auth/forgot-password">` element near the password input field
- [ ] Label the link "비밀번호를 잊으셨나요?" (or "Forgot your password?" depending on the project's locale)
- [ ] Style the link to be visually subtle (e.g., small font, muted color) so it does not compete with the primary login button
- [ ] Verify the link appears correctly on both desktop and mobile viewports
