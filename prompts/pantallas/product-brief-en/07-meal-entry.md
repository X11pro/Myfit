# Add or edit a meal · `/food/manual`

Design the main Nutrition input screen for Myfit. Keep manual entry usable without a barcode, photograph, or AI request.

- **Meal details:** name, meal type, calories in kcal, protein, carbohydrates, fat, sugar, and fiber in grams. Distinguish required fields, optional fields, unknown values, and actual zeroes.
- **Assisted entry:** offer barcode scan/manual code and camera/gallery photo actions. A result populates a reviewable draft; the user confirms the food and portion before saving. Keep ingredient and weight corrections close to estimates.
- **Navigation:** provide access to Food gallery and Shared food catalog. Editing an existing entry should show its saved values and a clear update action.
- **States:** show a blank manual form, a partly populated draft, validation, pending save, and completion. Explain an unavailable lookup without discarding typed values. Supported account records sync through Supabase; guest entries remain local.
