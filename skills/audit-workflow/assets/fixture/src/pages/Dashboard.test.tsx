import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { expect, test } from 'vitest'
import { AppRoutes } from '../App'

test('dashboard shows who is signed in', () => {
  render(
    <MemoryRouter initialEntries={['/dashboard']}>
      <AppRoutes />
    </MemoryRouter>,
  )
  expect(screen.getByRole('heading', { level: 1, name: 'Dashboard' })).toBeInTheDocument()
  expect(screen.getByText('Signed in as Ada Lovelace')).toBeInTheDocument()
})
