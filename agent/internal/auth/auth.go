package auth

import (
	"crypto/subtle"
	"net/http"
)

// Middleware validates the Bearer token in the Authorization header.
// If no token is configured, authentication is skipped.
func Middleware(token string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// If no token is set, skip auth
			if token == "" {
				next.ServeHTTP(w, r)
				return
			}

			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, `{"error":"missing authorization header"}`, http.StatusUnauthorized)
				return
			}

			// Expect "Bearer <token>"
			const prefix = "Bearer "
			if len(authHeader) <= len(prefix) || authHeader[:len(prefix)] != prefix {
				http.Error(w, `{"error":"invalid authorization format"}`, http.StatusUnauthorized)
				return
			}

			provided := authHeader[len(prefix):]
			if subtle.ConstantTimeCompare([]byte(provided), []byte(token)) != 1 {
				http.Error(w, `{"error":"invalid token"}`, http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
