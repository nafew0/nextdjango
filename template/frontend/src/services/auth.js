import api from './api'

export async function getSocialProviders() {
  const response = await api.get('/auth/social/providers/', {
    skipAuthRefresh: true,
    preserveAuthError: true,
  })
  return response.data
}

export async function startSocialLogin(provider, payload = {}) {
  const response = await api.post(`/auth/social/${provider}/start/`, payload, {
    skipAuthRefresh: true,
    preserveAuthError: true,
  })
  return response.data
}

export async function requestPasswordReset(identifier) {
  const response = await api.post('/auth/password-reset/request/', { identifier })
  return response.data
}

export async function validatePasswordReset(uid, token) {
  const response = await api.get('/auth/password-reset/validate/', {
    params: { uid, token },
  })
  return response.data
}

export async function confirmPasswordReset(payload) {
  const response = await api.post('/auth/password-reset/confirm/', payload)
  return response.data
}
