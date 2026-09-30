# FreelanceHub Design System

## Product
FreelanceHub is a modern freelance marketplace connecting clients
with freelancers.

The visual direction should feel:
- Modern
- Premium
- Minimal
- Professional
- Clean
- Trustworthy

Do NOT make the UI look like a generic student project.

---

# Brand

## Primary Color
Fiverr-inspired green:
#1DBF73

## Dark
#404145

## Background
#FFFFFF

## Secondary Background
#F7F7F7

## Border
#E4E4E4

## Text

Primary:
#222222

Secondary:
#74767E

Disabled:
#B5B5B5

---
# Iconography

## Icon System

Use **Lucide Icons** as the single icon family throughout FreelanceHub.

Do NOT use:
- Random icon packages
- Emoji as UI icons
- Unicode symbols
- Mixed icon families
- Random SVG icons copied from the internet
- Filled icons mixed with outlined Lucide icons unless explicitly specified

The Stitch design is a visual reference, but its individual icons
must NOT be copied blindly when they are inconsistent.

If a Stitch icon does not match the approved icon style,
replace it with the closest appropriate Lucide icon.

## Visual Style

Primary icon style:
- Clean
- Minimal
- Outline/stroke based
- Professional
- Consistent stroke weight

Default:
- Size: 24px
- Stroke width: 2px
- Color: inherit from surrounding UI
- Optical alignment: visually centered

Secondary icons:
- Size: 20px
- Stroke width: 2px

Small inline icons:
- Size: 16px
- Stroke width: 1.75–2px

Large feature icons:
- Size: 28–32px
- Stroke width: 2px

Do not make icons unnecessarily large.

## Icon Colors

Primary:
#404145

Secondary:
#74767E

Primary action:
#1DBF73

Disabled:
#B5B5B5

Destructive:
Use the established destructive/error color from the design system.

Do not introduce random icon colors.

## Filled vs Outlined

Default icon style is OUTLINED.

Use filled icons only for:
- Active/selected navigation state
- Strong semantic states where an outlined icon becomes unclear
- Explicitly defined UI states

Do not mix filled and outlined icons arbitrarily.

## Navigation Icons

Bottom navigation icons must:
- Use the same icon family
- Have identical visual weight
- Use 24px size
- Maintain consistent spacing
- Use a clearly distinguishable active state

Example:

Home
Search
Projects
Messages
Profile

## Icon Buttons

Icon-only buttons must:
- Have a minimum touch target of 44x44px
- Center the icon optically
- Use consistent icon sizing
- Avoid excessive decorative backgrounds

## Semantic Consistency

Use the same icon for the same meaning everywhere.

Examples:

Search → search
Notifications → bell
Messages → message-circle
Settings → settings
Profile → user
Favorite → heart
Share → share-2
Back → arrow-left
Close → x
More → more-horizontal

Do not use different icons for the same action on different screens.

## Icon Selection Rule

When an exact icon does not exist:

1. Choose the closest Lucide icon based on meaning.
2. Prefer a simple, recognizable symbol.
3. Prefer semantic clarity over visual decoration.
4. Keep the same visual weight as surrounding icons.

Never create a visually unusual icon just to match Stitch exactly.

## Consistency Rule

Before completing a screen, verify:

- Same icon family
- Same stroke weight
- Same sizing
- Same alignment
- Same color rules
- Same meaning across screens
- Same active/inactive behavior

The icon system must feel like one coherent product.
---

# Typography

Use:
Inter

Weights:
- Regular 400
- Medium 500
- SemiBold 600
- Bold 700

Avoid excessive font weights.

---

# UI Principles

1. Use generous whitespace.
2. Keep layouts visually simple.
3. Avoid overcrowding.
4. Use consistent 8px spacing.
5. Use rounded cards, but don't over-round everything.
6. Avoid excessive shadows.
7. Prefer subtle borders over heavy shadows.
8. Buttons should have clear hierarchy.
9. Important actions should be visually obvious.
10. Do not randomly introduce colors.

---

# Cards

Cards should:

- Have subtle borders
- Radius: 12–16px
- Minimal shadow
- Consistent internal padding
- Clear hierarchy

Do NOT create cards inside cards unless absolutely necessary.

---

# Buttons

Primary button:
- #1DBF73
- White text
- 12px radius
- Medium/Semibold text

Secondary button:
- White background
- #404145 text
- 1px #E4E4E4 border

Destructive:
- Use red only when necessary.

---

# Navigation

Bottom navigation should contain only the
most important destinations.

Example:

Home
Explore
Projects
Messages
Profile

Do not add unnecessary navigation items.

---

# Freelancer Cards

Show:

- Profile photo
- Freelancer name
- Verification if applicable
- Professional title
- Rating
- Review count
- Starting price
- Relevant skills

Keep information scannable.

---

# Gig / Service Cards

Show:

- Cover image
- Service title
- Freelancer
- Rating
- Starting price

Avoid showing too much text.

---

# Freelancer Profile

Hierarchy:

Profile photo
Name
Professional title
Rating
Bio
Skills
Portfolio
Reviews
Pricing
CTA

Primary CTA should remain visible.

---

# UX

Every screen must have:

1. Clear hierarchy
2. Clear primary action
3. Consistent spacing
4. Consistent typography
5. Consistent component styling

Do not create UI merely to fill space.

---

# IMPORTANT

Before changing an existing screen:

1. Inspect the current implementation.
2. Identify the existing components.
3. Preserve working functionality.
4. Improve the visual hierarchy.
5. Reuse existing components where possible.
6. Do not rewrite working backend/business logic just to change UI.

When a design decision is unclear, prefer:
minimal + professional + marketplace-oriented.