import { Button } from '../components/Button'
import { currentUser } from '../user'

export function Dashboard() {
  return (
    <>
      <header className="page-header">
        <h1>Dashboard</h1>
        <div className="header-actions">
          <span>Signed in as {currentUser.name}</span>
        </div>
      </header>
      <main>
        <section className="cards">
          <article className="card">
            <h2>Open tasks</h2>
            <p>12</p>
          </article>
          <article className="card">
            <h2>Messages</h2>
            <p>3</p>
          </article>
        </section>
        <Button variant="primary">New task</Button>
      </main>
    </>
  )
}
