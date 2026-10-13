import { useParams } from 'react-router-dom'
import { currentUser } from '../user'

export function Profile() {
  const { id } = useParams()
  if (id !== currentUser.id) {
    return (
      <main>
        <h1>User not found</h1>
      </main>
    )
  }
  return (
    <main>
      <h1>{currentUser.name}</h1>
      <dl>
        <dt>Email</dt>
        <dd>{currentUser.email}</dd>
        <dt>Role</dt>
        <dd>{currentUser.role}</dd>
      </dl>
    </main>
  )
}
