# Verify email code · `/auth/verify`

Design Myfit’s OTP verification screen, entered immediately after requesting a sign-in email. Show the destination address so the user can spot a typo.

- Group the six digits visually while retaining accessible input and paste. After the sixth digit, dismiss the keyboard and attempt verification. Show visible progress and suppress duplicate requests.
- Place an inline explanation near the code for an incorrect or expired attempt. Offer resend after the cooldown, display the remaining wait, and provide a way back to correct the email.
- Successful Supabase verification leads to onboarding; a complete profile can continue to the dashboard. Never display a real code, session token, or personal email in design examples.
