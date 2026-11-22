# Meal photo analysis · embedded meal-entry flow

Design a review panel for a meal photo taken with the camera or selected from the gallery. Show a preview and a deliberate “Analyze with AI” action. Attaching a photo alone should not imply that nutrition has been calculated.

After analysis, show the estimated food, confidence score, editable ingredients, total weight in grams, and estimated calories/macros. Let the user change the portion and see values recalculate proportionally, or request a fresh analysis using corrected ingredients and weight. Make the difference between these actions clear. Require food and portion confirmation before saving.

The `meal-photo-analyze` Edge Function returns structured estimates through OpenRouter; Qwen3 VL has been used. Supabase Storage supports authenticated meal photos. Keep provider credentials off the client. Distinguish analyzing, low confidence, incomplete response, failed connection, and reviewed draft. Do not present image estimates as measured facts.
