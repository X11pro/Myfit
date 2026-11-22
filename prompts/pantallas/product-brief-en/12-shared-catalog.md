# Shared food catalog · `/food/shared-catalog`

Design Myfit’s shared product workflow. Make the difference between **saving a reusable product** and **logging food eaten today** explicit.

Group the product name, brand, and barcode first. Follow with nutrition-label capture or input, available extracted values, and a review step before submission. Show a nutrition score when available and label its meaning separately from AI confidence. Support scanning or typing a barcode.

The `food-catalog-upsert` backend handles shared catalog operations; label analysis can assist data entry. Show missing fields, unreadable labels, pending submission, success, and recoverable errors. This catalog needs broader QA: do not represent entries as clinically verified or invent missing nutrients.
