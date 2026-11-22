# Barcode lookup result · embedded review

Design the product review state after Myfit scans a barcode or receives a manually entered code. This is part of the food workflow, not a new bottom tab.

- Show the matched product, brand when known, barcode, and available nutrition facts. Make the nutrition basis clear before applying values to a meal; distinguish serving quantities from values per 100 g when supplied.
- The `food-barcode-lookup` backend can use the shared Supabase catalog/cache, Open Food Facts, and a USDA FoodData Central fallback where configured. Do not imply every database returned a match.
- Provide distinct searching, matched, no-match, and network-error states. Let the user review, correct, retry, or continue manually. Only the subsequent meal save should create the food entry.
