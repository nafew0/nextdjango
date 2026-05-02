import { startTransition, useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { AlertCircle, LoaderCircle, MailCheck } from 'lucide-react'

import AuthShell from '@/components/auth/AuthShell'
import { Button } from '@/components/ui/button'
import BrandLogo from '@/components/branding/BrandLogo'
import { getSafeRedirect } from '@/utils/redirects'
import { useAuth } from '@/contexts/AuthContext'

const PROVIDER_LABELS = {
  google: 'Google',
  facebook: 'Facebook',
  github: 'GitHub',
}

export default function SocialAuthCallback() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const { completeCookieLogin, isAuthenticated, loading: authLoading } = useAuth()
  const [processing, setProcessing] = useState(searchParams.get('status') === 'success')
  const [resolvedStatus, setResolvedStatus] = useState(searchParams.get('status') || 'error')
  const [resolvedMessage, setResolvedMessage] = useState(
    searchParams.get('detail') || 'Social login could not be completed.'
  )
  const attemptedRef = useRef(false)

  const provider = (searchParams.get('provider') || '').toLowerCase()
  const providerName = PROVIDER_LABELS[provider] || 'Social login'
  const nextPath = getSafeRedirect(searchParams.get('next'))
  const emailHint = searchParams.get('email_hint') || ''

  useEffect(() => {
    if (resolvedStatus !== 'success' || authLoading || attemptedRef.current) {
      return
    }

    attemptedRef.current = true

    const finishLogin = async () => {
      if (isAuthenticated) {
        startTransition(() => {
          navigate(nextPath, { replace: true })
        })
        return
      }

      const result = await completeCookieLogin()
      if (result.success) {
        startTransition(() => {
          navigate(nextPath, { replace: true })
        })
        return
      }

      setProcessing(false)
      setResolvedStatus('error')
      setResolvedMessage(result.error || 'Social login session is unavailable.')
    }

    finishLogin()
  }, [authLoading, completeCookieLogin, isAuthenticated, navigate, nextPath, resolvedStatus])

  if (resolvedStatus === 'success' || processing) {
    return (
      <AuthShell>
        <div className="space-y-4">
          <BrandLogo />
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-[rgb(var(--theme-secondary-soft-rgb))] text-[rgb(var(--theme-secondary-rgb))]">
            <LoaderCircle className="h-5 w-5 animate-spin" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-[rgb(var(--theme-primary-ink-rgb))]">
              Finishing {providerName} sign-in
            </h1>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              You&apos;ll be redirected as soon as the session is ready.
            </p>
          </div>
        </div>
      </AuthShell>
    )
  }

  if (resolvedStatus === 'verification_required') {
    return (
      <AuthShell>
        <div className="space-y-4">
          <BrandLogo />
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-[rgb(var(--theme-secondary-soft-rgb))] text-[rgb(var(--theme-secondary-rgb))]">
            <MailCheck className="h-5 w-5" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-[rgb(var(--theme-primary-ink-rgb))]">
              Verify your email
            </h1>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              {resolvedMessage}
              {emailHint ? ` We sent a verification link to ${emailHint}.` : ''}
            </p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <Button asChild className="flex-1">
              <Link to="/login">Back to sign in</Link>
            </Button>
            <Button asChild variant="outline" className="flex-1">
              <Link to="/register">Open registration</Link>
            </Button>
          </div>
        </div>
      </AuthShell>
    )
  }

  return (
    <AuthShell>
      <div className="space-y-4">
        <BrandLogo />
        <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10 text-destructive">
          <AlertCircle className="h-5 w-5" />
        </div>
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-[rgb(var(--theme-primary-ink-rgb))]">
            {providerName} sign-in failed
          </h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            {resolvedMessage}
          </p>
        </div>
        <div className="flex flex-col gap-3 sm:flex-row">
          <Button asChild className="flex-1">
            <Link to="/login">Back to sign in</Link>
          </Button>
          <Button asChild variant="outline" className="flex-1">
            <Link to="/register">Create account</Link>
          </Button>
        </div>
      </div>
    </AuthShell>
  )
}
