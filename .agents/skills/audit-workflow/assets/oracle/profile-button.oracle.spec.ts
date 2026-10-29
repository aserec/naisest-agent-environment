import { expect, test } from '@playwright/test'

type Marked = Window & { __noReload?: boolean }

test('oracle: View profile opens the profile without a full page load', async ({ page }) => {
  await page.goto('/dashboard')
  const header = page.getByRole('banner')
  await header.screenshot({ path: test.info().outputPath('header.png') })
  await page.evaluate(() => { (window as Marked).__noReload = true })
  await header.getByRole('button', { name: 'View profile' }).click()
  await expect(page).toHaveURL(/\/profile\/u_42$/)
  await expect(page.getByRole('heading', { level: 1, name: 'Ada Lovelace' })).toBeVisible()
  expect(await page.evaluate(() => (window as Marked).__noReload)).toBe(true)
})

test('oracle: View profile works from the keyboard', async ({ page }) => {
  await page.goto('/dashboard')
  await page.getByRole('banner').getByRole('button', { name: 'View profile' }).focus()
  await page.keyboard.press('Enter')
  await expect(page).toHaveURL(/\/profile\/u_42$/)
})
