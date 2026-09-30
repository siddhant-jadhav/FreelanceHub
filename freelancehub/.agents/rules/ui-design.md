---
trigger: always_on
---

---
trigger: always_on
description: "FreelanceHub UI/UX design system and visual refinement rules."
---

# FreelanceHub UI Rules

The project must follow the design system defined in:

@[FreelanceHub Design System](../../docs/design.md)

These rules apply whenever creating, modifying, or reviewing UI.

## Before editing UI

Read the design system and inspect the existing implementation.

Do not blindly replace existing screens.

## Refinement requirements

When a screen looks functional but visually unrefined:

- Improve spacing
- Improve typography hierarchy
- Improve alignment
- Improve component consistency
- Reduce visual clutter
- Improve button hierarchy
- Improve card hierarchy
- Improve whitespace
- Improve information density
- Improve visual grouping

Do NOT change functionality unless specifically requested.
# Icon Enforcement

Icons are a controlled part of the FreelanceHub design system.

Use ONLY the approved Lucide icon system.

When implementing Stitch screens:

1. Inspect the Stitch icon.
2. Determine its semantic meaning.
3. Find the closest Lucide equivalent.
4. Replace the Stitch icon if its style is inconsistent.
5. Preserve the intended meaning and placement.

Do NOT reproduce inconsistent Stitch icons merely because they
appear in the reference.

Do NOT introduce another icon library.

Do NOT use:
- Emoji
- Unicode symbols
- Material Icons for convenience
- Cupertino Icons for convenience
- Random SVG icons
- Mixed icon families

Maintain:
- 24px default icons
- 20px secondary icons
- 16px inline icons
- Consistent stroke weight
- Consistent visual alignment

For repeated actions, use exactly the same icon everywhere.

Before finishing a screen, audit all icons for consistency.

## Avoid

- Random colors
- Excessive gradients
- Excessive shadows
- Huge headings
- Excessive rounded containers
- Nested cards
- Inconsistent spacing
- Random icon styles
- Different corner radii throughout the app
- Generic AI-generated dashboard aesthetics
- Unnecessary decorative elements

## Existing UI

If an existing screen already works:

PRESERVE:
- functionality
- navigation
- API calls
- state management
- models
- backend integration

CHANGE ONLY:
- visual hierarchy
- styling
- spacing
- typography
- component presentation
- responsiveness

## Quality check

Before considering a UI task complete:

- Compare the screen against design.md.
- Check spacing consistency.
- Check typography hierarchy.
- Check colors.
- Check button hierarchy.
- Check empty states.
- Check loading states.
- Check error states.
- Check overflow/responsiveness.