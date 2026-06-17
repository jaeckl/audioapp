# US-07-06 — Landscape bottom navigation

## Summary

In landscape, the shell bottom tab bar stays pinned to the bottom edge (never relocates to a side rail). Icons rotate; labels hide so content height is preserved.

## Acceptance

- [ ] `bottomNavigationBar` remains at bottom in landscape
- [ ] Tab icons rotate 90° in landscape
- [ ] Tab labels hidden in landscape
- [ ] Fixed 64dp bar height; side safe-area padding only (not extra bottom inset)

## Touchpoints

- `app_flutter/lib/app/daw_bottom_nav_bar.dart`
- `app_flutter/lib/app/daw_shell.dart`

[interaction](US-07-06-interaction.md) · [ux-ui](US-07-06-ux-ui.md)



## Companion stories

- [UX/UI](US-07-06-ux-ui.md)
- [Interaction](US-07-06-interaction.md)

## Status

**Done**
