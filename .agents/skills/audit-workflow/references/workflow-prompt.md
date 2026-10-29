Implement the feature described in `FEATURE.md` in this repository.

Nobody will answer questions during this run. When a decision is open, make it yourself and write it down in the file of the current phase.

Work through these seven phases in order. Use whatever skills, agents, and tools your setup gives you for each phase. A phase ends when you write its file under `.audit/`. Write each file once, at the end of its phase, and keep it short: what you did, what you decided, and what you found.

1. Research: read the code and docs the feature touches. Write `.audit/01-research.md`.
2. Spec: state what will be built and how it is accepted. Write `.audit/02-spec.md`.
3. Plan: list the steps and the tests. Write `.audit/03-plan.md`.
4. Implementation: change the code and add the tests. Write `.audit/04-implementation.md`.
5. Validation: run the unit tests, the Playwright tests, and the type check. Fix what fails. Write `.audit/05-validation.md` with each command and its result.
6. Code review: review the diff against the spec and the repository conventions, and fix what the review finds. Write `.audit/06-review.md`.
7. Final validation: run every check again after the review fixes. Write `.audit/07-final-validation.md` with each command and its result.

Stop after writing `.audit/07-final-validation.md`.
