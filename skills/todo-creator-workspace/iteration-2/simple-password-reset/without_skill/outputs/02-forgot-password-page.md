# Forgot Password Page

Create a dedicated `/auth/forgot-password` page where users can submit their email address to receive a password reset link. This page is reached from the "Forgot Password" link on the login page.

- [ ] Create `app/auth/forgot-password/page.tsx` as a Client Component (`"use client"`)
- [ ] Add a form with a single email input field and a submit button labeled "Send Reset Link"
- [ ] Manage form state (email value, loading state, error message, success message) using `useState`
- [ ] On form submission, call `POST /api/auth/forgot-password` with the email in the request body
- [ ] Display a loading indicator on the submit button while the request is in flight
- [ ] On success, replace the form with a confirmation message such as "Check your email for a reset link."
- [ ] On error, display a user-friendly error message below the form
- [ ] Add a "Back to Login" link pointing to `/auth/login`
- [ ] Apply consistent styling using the project's existing design system or Tailwind CSS classes
