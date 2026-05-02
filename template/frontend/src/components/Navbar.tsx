'use client'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useAuth } from '../contexts/AuthContext'
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ClipboardList, CreditCard, Star, User, LogOut, LayoutDashboard, Settings, ShieldCheck } from "lucide-react"
import BrandLogo from '@/components/branding/BrandLogo'
import ThemeStudioDialog from '@/components/theme/ThemeStudioDialog'
import useAdminAccess from '@/hooks/useAdminAccess'
import { resolveApiAssetUrl } from '@/services/api'

const Navbar = () => {
  const { user, logout, isAuthenticated } = useAuth()
  const { canAccessAdmin } = useAdminAccess()
  const router = useRouter()
  const currentPlanSlug = (user?.current_plan?.slug || 'free').toLowerCase()
  const currentPlanTier = Number(user?.current_plan?.tier || 0)
  const isUpgraded =
    currentPlanTier > 0 || (currentPlanSlug !== '' && currentPlanSlug !== 'free')

  const handleLogout = async () => {
    await logout()
    router.push('/login')
  }

  const getUserInitials = () => {
    if (user?.first_name && user?.last_name) {
      return `${user.first_name[0]}${user.last_name[0]}`.toUpperCase()
    }
    return user?.username?.substring(0, 2).toUpperCase() || 'U'
  }

  return (
    <nav className="fixed inset-x-0 top-0 z-50 border-b border-[rgb(var(--theme-border-rgb)/0.85)] bg-[rgb(var(--theme-neutral-rgb)/0.92)] backdrop-blur">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center h-16">
          <Link href="/" className="flex items-center gap-3">
            <BrandLogo compact />
          </Link>

          <div className="hidden flex-1 lg:block" />

          <div className="flex items-center gap-3">
            <div className="hidden md:block">
              <Link href="/pricing">
                <Button variant="ghost" className="rounded-full gap-2">
                  {isUpgraded ? <Star className="h-4 w-4 text-[rgb(var(--theme-primary-rgb))]" /> : null}
                  {isUpgraded ? 'Pro' : 'Upgrade'}
                </Button>
              </Link>
            </div>
            <div className="hidden md:block">
              <ThemeStudioDialog />
            </div>
            {isAuthenticated ? (
              <>
                <Link href="/dashboard">
                  <Button variant="ghost" className="rounded-full">Dashboard</Button>
                </Link>

                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="relative h-10 w-10 rounded-full">
                      <Avatar className="h-10 w-10">
                        <AvatarImage src={resolveApiAssetUrl(user?.avatar)} alt={user?.full_name || user?.username} />
                        <AvatarFallback className="bg-[rgb(var(--theme-secondary-soft-rgb))] text-[rgb(var(--theme-secondary-ink-rgb))]">
                          {getUserInitials()}
                        </AvatarFallback>
                      </Avatar>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-56 rounded-2xl" align="end" forceMount>
                    <DropdownMenuLabel className="font-normal">
                      <div className="flex flex-col space-y-1">
                        <p className="text-sm font-medium leading-none">{user?.username}</p>
                        <p className="text-xs leading-none text-muted-foreground">
                          {user?.email}
                        </p>
                      </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem onClick={() => router.push('/dashboard')}>
                      <ClipboardList className="mr-2 h-4 w-4" />
                      <span>Dashboard</span>
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => router.push('/dashboard')}>
                      <LayoutDashboard className="mr-2 h-4 w-4" />
                      <span>Dashboard</span>
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => router.push('/profile')}>
                      <User className="mr-2 h-4 w-4" />
                      <span>Profile</span>
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => router.push('/pricing')}>
                      <CreditCard className="mr-2 h-4 w-4" />
                      <span>Upgrade</span>
                    </DropdownMenuItem>
                    {canAccessAdmin ? (
                      <DropdownMenuItem onClick={() => router.push('/admin')}>
                        <ShieldCheck className="mr-2 h-4 w-4" />
                        <span>Admin Panel</span>
                      </DropdownMenuItem>
                    ) : null}
                    <DropdownMenuItem>
                      <Settings className="mr-2 h-4 w-4" />
                      <span>Settings</span>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem onClick={handleLogout}>
                      <LogOut className="mr-2 h-4 w-4" />
                      <span>Log out</span>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </>
            ) : (
              <>
                <Link href="/login">
                  <Button variant="ghost" className="rounded-full">Log in</Button>
                </Link>
                <Link href="/register">
                  <Button className="rounded-full">Start free</Button>
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}

export default Navbar
