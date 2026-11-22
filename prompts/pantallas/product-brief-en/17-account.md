# Account and privacy · authenticated state of `/auth`

Design Myfit’s signed-in account view and its export/delete confirmation states. Make the account identity easy to verify without exposing tokens. Explain that signing out, exporting records, and deleting remote data are different operations.

Give export an ordinary action and place destructive deletion separately with clear scope, confirmation, and a cancel path. Show pending, completed, and failed operations. The `user-data-manage` Edge Function supports basic authenticated export and remote deletion. Do not promise removal of every local copy, specific advanced export formats, or seamless migration of guest records. For a guest, direct account-only actions to sign-in rather than implying that cloud records already exist.
