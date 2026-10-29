import type { ButtonHTMLAttributes } from 'react'

type Props = ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' }

export function Button({ variant = 'primary', className = '', ...rest }: Props) {
  return (
    <button type="button" data-variant={variant} className={`btn btn-${variant} ${className}`.trim()} {...rest} />
  )
}
