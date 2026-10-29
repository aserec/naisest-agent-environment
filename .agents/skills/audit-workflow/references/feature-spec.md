# Feature: View profile button on the dashboard

The dashboard header gets a button that takes the signed-in user to their profile page.

## Design

- Label: exactly `View profile`.
- Place: inside the dashboard header, in the `.header-actions` group, after the "Signed in as" text.
- Look: the existing `Button` component from `src/components/Button.tsx` with `variant="secondary"`. No new CSS, no inline styles, no new class names.
- Action: on click or Enter, go to `/profile/<id of the current user>` with client-side routing. The page must not reload.

## Constraints

- Do not change `Button.tsx`, `Profile.tsx`, or `src/styles.css`.
- Do not add dependencies.
- Add one unit test (Vitest + Testing Library) and one Playwright test that prove the button is there and takes the user to the profile.
- Leave every existing test passing, and keep `npm run typecheck` clean.
