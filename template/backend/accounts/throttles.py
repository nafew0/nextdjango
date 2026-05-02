import hashlib
import re

from django.conf import settings
from rest_framework.throttling import SimpleRateThrottle

from .verification import get_request_ip_address


def _hash_identifier(value):
    normalized = (value or "").strip().lower()
    if not normalized:
        return ""
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


class LoginRateThrottle(SimpleRateThrottle):
    rate = "10/min"
    scope = "public_login"

    def get_cache_key(self, request, view):
        identifier = _hash_identifier(
            request.data.get("username") or request.data.get("identifier") or ""
        )
        client_ip = get_request_ip_address(request) or "unknown"
        ident = f"{client_ip}:{identifier}" if identifier else client_ip
        return self.cache_format % {
            "scope": self.scope,
            "ident": ident,
        }


class VariableWindowRateThrottle(SimpleRateThrottle):
    rate = None
    default_rate = None
    rate_setting = ""

    def __init__(self):
        self.rate = self.get_rate()
        self.num_requests, self.duration = self.parse_rate(self.rate)

    def get_rate(self):
        configured_rate = (
            getattr(settings, self.rate_setting, "").strip()
            if self.rate_setting
            else ""
        )
        return configured_rate or self.default_rate

    def parse_rate(self, rate):
        if rate is None:
            return (None, None)

        num_requests, period = rate.split("/")
        match = re.fullmatch(r"(?:(\d+))?([smhd])", period.strip().lower())
        if not match:
            return super().parse_rate(rate)

        multiplier = int(match.group(1) or "1")
        unit = match.group(2)
        duration = {
            "s": 1,
            "m": 60,
            "h": 60 * 60,
            "d": 60 * 60 * 24,
        }[unit] * multiplier
        return int(num_requests), duration


class RegisterIPRateThrottle(VariableWindowRateThrottle):
    def get_cache_key(self, request, view):
        client_ip = get_request_ip_address(request) or "unknown"
        return self.cache_format % {
            "scope": self.scope,
            "ident": client_ip,
        }


class RegisterBurstRateThrottle(RegisterIPRateThrottle):
    scope = "public_register_burst"
    default_rate = "1/15s"
    rate_setting = "SIGNUP_REGISTER_BURST_RATE"


class RegisterShortWindowRateThrottle(RegisterIPRateThrottle):
    scope = "public_register_short_window"
    default_rate = "3/10m"
    rate_setting = "SIGNUP_REGISTER_SHORT_WINDOW_RATE"


class RegisterSustainedRateThrottle(RegisterIPRateThrottle):
    scope = "public_register_sustained"
    default_rate = "10/h"
    rate_setting = "SIGNUP_REGISTER_SUSTAINED_RATE"


class SocialLoginRateThrottle(VariableWindowRateThrottle):
    scope = "public_social_login"
    default_rate = "10/min"

    def get_cache_key(self, request, view):
        client_ip = get_request_ip_address(request) or "unknown"
        return self.cache_format % {
            "scope": self.scope,
            "ident": client_ip,
        }


class AdminRateThrottle(VariableWindowRateThrottle):
    scope = "admin_api"
    default_rate = "100/hour"

    def get_cache_key(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return None
        return self.cache_format % {
            "scope": self.scope,
            "ident": request.user.pk,
        }
