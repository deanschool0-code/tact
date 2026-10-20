# Bugs

Found and fixed during build (all S3, caught by tests before shipping):
- BUG-001 S3 `_strs`/`_items` treated a string as a list → stray characters in flags. Fixed in tact/ai.py, test `test_normalise_coerces_bad_shapes`.
- BUG-002 S3 OCR continuation could resume twice on a Vision error (crash). Fixed: synchronous perform, single resume.

Open: none reproduced. To check (needs Xcode build): compile on Xcode 16+, App Group signing with a free Apple ID, StoreKit scheme path.
