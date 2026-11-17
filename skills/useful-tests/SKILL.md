---
name: useful-tests
description: Proves each test fails when one caller-visible behavior breaks. Use for every code change and every task that writes, edits, or reviews tests.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - testing
    - code-review
---

# Useful tests

## Purpose

Use this when a test is being added or judged. A test stays when it proves one caller-visible behavior and goes red if that behavior breaks. It stays green when only the internals change.

Keep a test only when a wrong outcome turns it red. Otherwise delete it, or rewrite the assertion until a wrong outcome fails it.

The work is done when every item in the [Checklist](#checklist) at the end of this file holds.

## Instructions

Run this on every test you add or edit, and on every existing test in the files you are reviewing.

- In a red-green loop, run steps 1 to 4 on the test before you write the production code, and steps 1 to 5 again before you finish. Step 5 cannot pass while the test is still red.
- When you are judging tests and leaving the edits to someone else, change no test file. Where a step says rewrite, delete, or remove, mark the test with that verdict and report it in step 6.

### 1. Name the behavior

For each test, write one sentence a caller would recognize. State the input, the action, and the outcome.

Done when every test has that sentence, or is marked delete because no caller-visible outcome exists.

### 2. Name the break

State one production change that makes this test fail. The change alters the named outcome.

Done when each kept test has that change. Rewrite or delete a test that has none.

### 3. Separate the expected result from the code

Take the expected value from a literal, the spec, or a worked example. Compute it by a different method than the code under test.

Done when each assertion's expected value has that separate source.

### 4. Read the outcome at the caller's interface

Assert on a return value, an error, state read back through the same public interface, rendered output, or an event the caller subscribed to.

Done when each kept test observes the outcome there.

### 5. Close the suite

Remove any test whose only job is to execute a line, a branch, or a coverage target. Run the project's test command for the tests you changed.

Done when each remaining test has a behavior sentence and a break, and that command passes. A green run of a test that proves nothing is unfinished.

### 6. Report the verdicts

Do this step only when you are judging tests and leaving the edits to someone else. Report each test as keep, rewrite, or delete.

- **keep.** The behavior sentence, and the production change that turns the test red.
- **rewrite.** The behavior worth keeping, and what the current assertion fails to prove.
- **delete.** Why the test proves no caller-visible outcome.

A deleted test gets a replacement only when a caller-visible behavior is now unproved. Name that behavior on the delete line.

Done when every test in the files under review has one verdict with the parts named above.

## Keep a test when all of these hold

- It names one caller-visible outcome.
- Its expected value can disagree with the implementation.
- A production change to that outcome turns the test red.
- An internal-only change leaves the test green.

## Rewrite or delete a test when any of these hold

- The assertion passes for any implementation. An empty test, `expect(true).toBe(true)`, and an assertion on a mock the test itself arranged are the usual cases.
- The expected value is produced by the same steps as the implementation.
- The test checks that a collaborator was called, how many times, or in which order.
- The test exercises a private helper, and a public-interface test already proves the same outcome.
- Another test already proves the same outcome.
- The test was added to cover a line, a branch, or a percentage.
- A snapshot or golden file was generated from the implementation and never checked against an independent result.

When you rewrite, keep the behavior sentence and change the assertion so a wrong outcome fails.

## Before you add a test

Add a test only after you name the caller-visible behavior that no current test proves.

One test proves one behavior. A second assertion stays in the same test only when it checks that same outcome. A different outcome gets its own test.

## Examples

### Keep

```ts
test("checkout confirms a cart paid with a valid card", async () => {
  const cart = createCart();
  cart.add(productPriced(12));
  const result = await checkout(cart, validCard());
  expect(result.status).toBe("confirmed");
  expect(result.total).toBe(12);
});
```

A valid card confirms the cart and records the price. Returning status `failed` or total `0` turns the test red. The `12` is the known price of the product, taken from the fixture.

### Rewrite

```ts
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, item) => sum + item.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});
```

The expected value repeats the implementation, so a wrong sum still passes. Rewrite the assertion to `toBe(15)`.

### Delete

```ts
test("checkout calls payment.process once", async () => {
  const process = vi.fn();
  await checkout(cart, card, { process });
  expect(process).toHaveBeenCalledOnce();
});
```

The caller sees a confirmed or failed checkout. The call count is invisible to them. Delete this test. If no test yet asserts the checkout outcome, add that test instead.

### Review report

```text
Review of the Jev core tests, edits left to the author. 2 of the 8 tests shown.

keep: "mock is deterministic: identical request, identical answer"
  Behavior: the same request sent to the mock twice gives the same answer.
  Break: a random term in the token count of MockJev.systemOne turns the test red.

rewrite: "validateQuestions enforces the 255-option Choice cap"
  Behavior to keep: a choice question with 256 options is refused.
  Not proved: the test builds its options from LIMITS.MAX_CHOICE_OPTIONS + 1, the constant the code checks. With the cap set to 10 the test stays green.
```

Both are real tests from the Jev test folder of the agent-config repo. Each change named above was made in a copy of the code and gave the result stated.

## Prerequisites

You need the tests under review and the project's test command. Read that command from the project docs, package scripts, or task runner. This skill uses no extra tools, keys, or services.

## Limitations

This skill judges whether a test can fail when its named behavior breaks. It leaves product judgment, coverage targets, performance budgets, and screenshot diffs to the project's own rules.

## Troubleshooting

**The test stays green when the outcome is wrong.** The expected value is computed the same way as the code. Replace it with a literal, a spec value, or a worked example.

**Deleting a test leaves a behavior unproved.** Name that behavior and add one test that fails when it breaks.

**The suite cannot be closed.** The project test command is unknown or failing. Find the command in the project docs, package scripts, or task runner, fix the failure, and run it again before you finish.

## Checklist

Run this before you say the work is done. Fix every item that fails, then run it again.

- [ ] Every test you added, edited, or reviewed has a one-sentence behavior with input, action, and outcome, or is marked delete.
- [ ] Every kept test has one named production change that turns it red.
- [ ] Every expected value comes from a literal, the spec, or a worked example, and not from the method of the code under test.
- [ ] Every kept test reads the outcome at the caller's interface.
- [ ] No remaining test exists only to execute a line, a branch, or a coverage target.
- [ ] The project's test command ran for the tests you changed, and it passes.
- [ ] Red-green loop only: steps 1 to 4 ran on the test before the production code was written.
- [ ] Review only: every test has a keep, rewrite, or delete line with its parts, and no test file was edited.
