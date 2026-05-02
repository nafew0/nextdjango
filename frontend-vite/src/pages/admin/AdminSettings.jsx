import { useEffect, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'

import { useToast } from '@/hooks/useToast'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { CustomSelect } from '@/components/ui/custom-select'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import { getAdminSettings, testAdminAI, updateAdminSettings } from '@/services/admin'

function buildInitialState(settings) {
  return {
    require_email_verification: settings?.require_email_verification ?? true,
    logged_in_users_only_default: settings?.logged_in_users_only_default ?? false,
    social_login_google_enabled: settings?.social_login_google_enabled ?? false,
    social_login_facebook_enabled: settings?.social_login_facebook_enabled ?? false,
    social_login_github_enabled: settings?.social_login_github_enabled ?? false,
    ai_provider: settings?.ai_provider || 'openai',
    ai_model_openai: settings?.ai_model_openai || '',
    ai_model_anthropic: settings?.ai_model_anthropic || '',
  }
}

export default function AdminSettings() {
  const { toast } = useToast()
  const queryClient = useQueryClient()
  const [formState, setFormState] = useState(buildInitialState(null))
  const [saving, setSaving] = useState(false)
  const [testing, setTesting] = useState(false)

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: getAdminSettings,
  })

  useEffect(() => {
    setFormState(buildInitialState(data))
  }, [data])

  const handleChange = (key, value) => {
    setFormState((current) => ({
      ...current,
      [key]: value,
    }))
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      const payload = { ...formState }
      await updateAdminSettings(payload)
      await queryClient.invalidateQueries({ queryKey: ['admin-settings'] })
      toast({
        title: 'Settings saved',
        description: 'reactdjango updated the platform settings successfully.',
        variant: 'success',
      })
    } catch (requestError) {
      toast({
        title: 'Save failed',
        description: requestError.response?.data?.detail || 'reactdjango could not save settings right now.',
        variant: 'error',
      })
    } finally {
      setSaving(false)
    }
  }

  const handleTest = async () => {
    const provider = formState.ai_provider
    const model = provider === 'openai' ? formState.ai_model_openai : formState.ai_model_anthropic

    setTesting(true)
    try {
      const response = await testAdminAI({
        provider,
        model,
      })
      toast({
        title: 'Connection successful',
        description: response.message,
        variant: 'success',
      })
    } catch (requestError) {
      toast({
        title: 'Connection failed',
        description: requestError.response?.data?.detail || 'reactdjango could not validate the AI provider.',
        variant: 'error',
      })
    } finally {
      setTesting(false)
    }
  }

  if (isLoading) {
    return <div className="theme-panel rounded-[1.8rem] p-6 text-sm text-muted-foreground">Loading settings...</div>
  }

  if (error) {
    return <div className="theme-panel rounded-[1.8rem] p-6 text-sm text-rose-600">reactdjango could not load settings right now.</div>
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <Card className="theme-panel rounded-[1.8rem] border-0">
        <CardHeader>
          <CardTitle>Authentication defaults</CardTitle>
          <CardDescription>Global auth and collector defaults for new workspaces.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="flex items-center justify-between gap-4 rounded-[1.2rem] border border-[rgb(var(--theme-border-rgb)/0.76)] bg-white/80 px-4 py-3">
            <div>
              <p className="font-medium text-foreground">Require email verification</p>
              <p className="text-sm text-muted-foreground">New accounts must verify email before sign-in.</p>
            </div>
            <Switch
              checked={formState.require_email_verification}
              onCheckedChange={(value) => handleChange('require_email_verification', value)}
            />
          </div>

          <div className="flex items-center justify-between gap-4 rounded-[1.2rem] border border-[rgb(var(--theme-border-rgb)/0.76)] bg-white/80 px-4 py-3">
            <div>
              <p className="font-medium text-foreground">Logged-in respondents only by default</p>
              <p className="text-sm text-muted-foreground">New content defaults to authenticated users only.</p>
            </div>
            <Switch
              checked={formState.logged_in_users_only_default}
              onCheckedChange={(value) => handleChange('logged_in_users_only_default', value)}
            />
          </div>

          {[
            {
              key: 'social_login_google_enabled',
              title: 'Google social login',
              description: data.social_login_google_meta?.configured
                ? 'Allow users to sign in or sign up with Google.'
                : 'Add Google client credentials to the backend environment before enabling this provider.',
              configured: data.social_login_google_meta?.configured,
            },
            {
              key: 'social_login_facebook_enabled',
              title: 'Facebook social login',
              description: data.social_login_facebook_meta?.configured
                ? 'Allow Facebook login. First-time Facebook users must verify email before access is granted.'
                : 'Add Facebook client credentials to the backend environment before enabling this provider.',
              configured: data.social_login_facebook_meta?.configured,
            },
            {
              key: 'social_login_github_enabled',
              title: 'GitHub social login',
              description: data.social_login_github_meta?.configured
                ? 'Allow users to sign in or sign up with GitHub using a verified GitHub email.'
                : 'Add GitHub client credentials to the backend environment before enabling this provider.',
              configured: data.social_login_github_meta?.configured,
            },
          ].map((provider) => (
            <div
              key={provider.key}
              className="flex items-center justify-between gap-4 rounded-[1.2rem] border border-[rgb(var(--theme-border-rgb)/0.76)] bg-white/80 px-4 py-3"
            >
              <div>
                <div className="flex items-center gap-2">
                  <p className="font-medium text-foreground">{provider.title}</p>
                  <Badge variant={provider.configured ? 'success' : 'warning'}>
                    {provider.configured ? 'Configured' : 'Missing credentials'}
                  </Badge>
                </div>
                <p className="text-sm text-muted-foreground">{provider.description}</p>
              </div>
              <Switch
                checked={formState[provider.key]}
                onCheckedChange={(value) => handleChange(provider.key, value)}
                disabled={!provider.configured}
              />
            </div>
          ))}
        </CardContent>
      </Card>

      <Card className="theme-panel rounded-[1.8rem] border-0">
        <CardHeader>
          <CardTitle>AI provider configuration</CardTitle>
          <CardDescription>
            Provider selection and environment-managed AI secret status.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="grid gap-3 md:grid-cols-2">
            <div className="space-y-2">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-muted-foreground">Provider</p>
              <CustomSelect
                value={formState.ai_provider}
                onChange={(value) => handleChange('ai_provider', value)}
                options={[
                  { label: 'OpenAI', value: 'openai' },
                  { label: 'Anthropic', value: 'anthropic' },
                ]}
              />
            </div>
            <div className="space-y-2">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-muted-foreground">Default model</p>
              <Input
                value={formState.ai_provider === 'openai' ? formState.ai_model_openai : formState.ai_model_anthropic}
                onChange={(event) =>
                  handleChange(
                    formState.ai_provider === 'openai' ? 'ai_model_openai' : 'ai_model_anthropic',
                    event.target.value
                  )
                }
                placeholder={formState.ai_provider === 'openai' ? 'gpt-5-mini' : 'claude-3-7-sonnet-latest'}
              />
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="rounded-[1.2rem] border border-[rgb(var(--theme-border-rgb)/0.76)] bg-white/80 p-4">
              <div className="flex items-center justify-between gap-2">
                <p className="font-medium text-foreground">OpenAI key</p>
                <Badge variant={data.ai_api_key_openai_meta.configured ? 'success' : 'warning'}>
                  {data.ai_api_key_openai_meta.configured ? 'Configured' : 'Missing'}
                </Badge>
              </div>
              <p className="mt-2 text-sm text-muted-foreground">
                {data.ai_api_key_openai_meta.configured
                  ? 'Configured in the server environment. reactdjango does not expose provider secrets in the admin panel.'
                  : 'Configure `OPENAI_API_KEY` on the server to enable OpenAI requests and connection testing.'}
              </p>
            </div>

            <div className="rounded-[1.2rem] border border-[rgb(var(--theme-border-rgb)/0.76)] bg-white/80 p-4">
              <div className="flex items-center justify-between gap-2">
                <p className="font-medium text-foreground">Anthropic key</p>
                <Badge variant={data.ai_api_key_anthropic_meta.configured ? 'success' : 'warning'}>
                  {data.ai_api_key_anthropic_meta.configured ? 'Configured' : 'Missing'}
                </Badge>
              </div>
              <p className="mt-2 text-sm text-muted-foreground">
                {data.ai_api_key_anthropic_meta.configured
                  ? 'Configured in the server environment. reactdjango does not expose provider secrets in the admin panel.'
                  : 'Configure `ANTHROPIC_API_KEY` on the server to enable Anthropic requests and connection testing.'}
              </p>
            </div>
          </div>

          <div className="flex flex-wrap gap-3">
            <Button className="rounded-xl" onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : 'Save settings'}
            </Button>
            <Button variant="outline" className="rounded-xl" onClick={handleTest} disabled={testing}>
              {testing ? 'Testing...' : 'Test connection'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
