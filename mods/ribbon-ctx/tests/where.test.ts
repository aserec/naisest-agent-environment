import { expect, test } from 'claude-code/testing'

import { whereOf } from '../hooks/register'

test('the main checkout reads as its folder and branch, with no worktree', () => {
  expect(whereOf('/p/app/apps/web', '/p/app\nmain\n/p/app/.git\n')).toEqual({
    folder: 'app/apps/web',
    branch: 'main',
    worktree: null,
  })
})

test('a linked worktree is named by its own top folder', () => {
  expect(whereOf('/p/wt/fix', '/p/wt/fix\nhotfix/x\n/p/app/.git\n')).toEqual({
    folder: 'fix',
    branch: 'hotfix/x',
    worktree: 'fix',
  })
})

test('outside git only the folder shows; a detached head says so', () => {
  expect(whereOf('/tmp/scratch', null)).toEqual({ folder: 'scratch', branch: null, worktree: null })
  expect(whereOf('/p/app', '/p/app\nHEAD\n/p/app/.git\n').branch).toBe('detached')
})
