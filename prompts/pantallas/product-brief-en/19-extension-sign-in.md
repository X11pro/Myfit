# Chrome Routine Builder · access states

Design the setup and authentication states inside a compact Chrome popup. If project configuration is missing, display “Connect Myfit” and a clear action opening connection settings. Otherwise show an email form explaining that the user should use the same account as on mobile.

After requesting an OTP, switch to a one-time code field, “Verify and continue,” and “Use a different email.” Distinguish these explicit desktop controls from mobile auto-verification. Show sending, verification errors, and successful entry into the builder. When reopening the popup, a stored Supabase session may renew automatically; if renewal fails, guide the user back to sign-in without implying remote routines were deleted.
