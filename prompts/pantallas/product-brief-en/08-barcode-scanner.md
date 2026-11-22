# Scan a barcode · camera flow

Design the scanner launched from Myfit’s food entry or shared catalog. Make aiming the camera at a single product barcode the primary task. Show the scanning region, a short instruction, and a clear exit back to the originating flow.

Explain camera access at the point of use. If permission is denied, scanning is unavailable, or the code cannot be read, offer manual code entry in the calling flow. Keep codes as identifiers, including leading zeroes. Distinguish detecting a code from finding a matching product: detection starts a lookup and must not automatically log a meal.
