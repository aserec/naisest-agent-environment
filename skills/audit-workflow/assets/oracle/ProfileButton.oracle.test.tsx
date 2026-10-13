import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { expect, test } from 'vitest'
import { AppRoutes } from '../App'

test('oracle: header has a secondary View profile button that opens the current user profile', async () => {
  render(
    <MemoryRouter initialEntries={['/dashboard']}>
      <AppRoutes />
    </MemoryRouter>,
  )
  const header = screen.getByRole('banner')
  const button = within(header).getByRole('button', { name: 'View profile' })
  expect(button).toHaveAttribute('data-variant', 'secondary')
  expect(button).not.toHaveAttribute('style')
  expect(button.closest('.header-actions')).not.toBeNull()
  await userEvent.click(button)
  expect(screen.getByRole('heading', { level: 1, name: 'Ada Lovelace' })).toBeInTheDocument()
})
