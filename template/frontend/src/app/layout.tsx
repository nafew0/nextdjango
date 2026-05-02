import type { Metadata } from 'next'
import './globals.css'
import Providers from './providers'
import ClientShell from './ClientShell'

export const metadata: Metadata = {
  title: 'reactdjango',
  description: 'A Django + React boilerplate',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="flex min-h-full flex-col">
        <Providers>
          <ClientShell>{children}</ClientShell>
        </Providers>
      </body>
    </html>
  )
}
