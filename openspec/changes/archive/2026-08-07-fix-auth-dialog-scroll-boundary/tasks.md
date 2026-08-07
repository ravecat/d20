## 1. Dialog Body Scroll Boundary

- [x] 1.1 Move the account description and conditional notices into the existing content container while keeping the title row outside it.
- [x] 1.2 Make the content container a shrinking column that preserves the current spacing and owns the only internal vertical overflow.
- [x] 1.3 Move the responsive surface inset onto the fixed title row and scroll body so the body scrollport spans the dialog surface without a custom property.

## 2. Regression Coverage And Validation

- [x] 2.1 Extend the focused mobile browser test to prove the body starts with the description, scrolls through the final mode content, and leaves the title row fixed.
- [x] 2.2 Run focused formatting, lint, type checking, browser tests, diff checks, and strict OpenSpec validation.
- [x] 2.3 Cover desktop and mobile full-width scrollport geometry plus retained child insets without asserting native scrollbar width.
- [x] 2.4 Re-run focused validation and strict OpenSpec checks after the scrollbar-edge refinement.
