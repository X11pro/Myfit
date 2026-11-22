# Energy profile · `/onboarding` and `/profile`

Design one reusable Myfit form in two contexts: completing the profile before first use, and editing it later from the dashboard’s estimated burn card.

- Group body measurements (weight in kg, height with units), date of birth, and optional sex separately from the user’s goal and everyday activity. Describe the four activity levels in language that distinguishes daily movement from logging a workout.
- In edit mode, prefill the profile. Keep units, date format, optional labels, inline validation, and the save action visible at large text sizes. Explain why the fields are requested.
- The data informs a Mifflin–St Jeor-based energy estimate where applicable, with a fallback when unavailable. Describe the result as estimated expenditure, not a measurement or diagnosis. Saving a complete onboarding profile opens Home.
