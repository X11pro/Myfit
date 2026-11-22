# Email sign-in · `/auth`

Design the signed-out state of Myfit’s account screen. Its task is to request an email code, not a password.

- Place a labeled email field and a “Send code” action together. Explain that a six-digit, one-time code will arrive by email. Keep guest access visible where account services are unavailable.
- Use Supabase Auth for the request. Show submitting feedback, prevent repeated submissions while pending, and associate invalid-email or network errors with the form. Preserve the address for correction.
- On success, carry the address to the verification screen. Do not mark the user as signed in merely because a message was sent.
- Show the narrow-screen layout with the keyboard open. Use accessible labels and a mint primary action against the dark card.
