'use client'
import { usePathname } from 'next/navigation'

import Navbar from '@/components/Navbar'

const NO_NAVBAR_PATHS = ['/forgot-password', '/reset-password', '/auth/social/callback']

export default function ClientShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname() ?? ''
  const showNavbar = !NO_NAVBAR_PATHS.some((p) => pathname.startsWith(p))

  return (
    <>
      {showNavbar && <Navbar />}
      <main className={showNavbar ? 'pt-16' : ''}>{children}</main>
    </>
  )
}
