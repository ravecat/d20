# Sign in with Apple Enablement

Sign in with Apple is implemented but unavailable until all three runtime values are configured. Deploy them only after the Apple Developer configuration, automated checks, private relay setup, and full staging journey below are complete.

## Runtime variables

- `APPLE_CLIENT_ID` is the Apple Services ID used as the OAuth client id.
- `APPLE_TEAM_ID` is the Apple Developer Program Team ID.
- `APPLE_KEY_ID` identifies the Sign in with Apple private key.
- `APPLE_PRIVATE_KEY_BASE64` is the complete downloaded `.p8` private key encoded as one base64 value.
- `APPLE_CALLBACK_URL` is the exact registered HTTPS return URL and must end with `/auth/apple/callback` without query or fragment.

Never commit the `.p8` file, its base64 representation, decoded key, or generated client secret. Store the source credentials in the deployment secret store. Apple stays unavailable when any variable is unset. Supplying all five variables enables Apple; `D20Web.Auth.Apple` decodes the private key and delegates generation of a fresh client-secret JWT to Ueberauth for each provider flow, so operators do not manually rotate generated JWTs. Verify the source credentials and callback URL in staging before deployment.

## Apple Developer configuration

1. Enable Sign in with Apple on a primary App ID.
2. Register a Services ID for the D20 environment and associate it with that App ID.
3. Register the exact domain and `APPLE_CALLBACK_URL`. Apple does not accept localhost or IP return URLs.
4. Create a Sign in with Apple private key, generate the client-secret JWT, and configure its rotation in the deployment secret store.
5. Register and authenticate the D20 outbound email source used by Resend in Apple's private email relay configuration. Verify SPF and DKIM so messages sent to relay addresses do not bounce.

Apple setup references:

- [Configure Sign in with Apple for the web](https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web/)
- [Create a Sign in with Apple private key](https://developer.apple.com/help/account/capabilities/create-a-sign-in-with-apple-private-key/)
- [Configure private email relay service](https://developer.apple.com/help/account/capabilities/configure-private-email-relay-service/)

## Staging verification

Keep production disabled until all checks pass in a real HTTPS staging environment:

- New registration with a personal Apple email reaches username completion and creates one confirmed D20 user and one Apple identity.
- New registration with Hide My Email accepts the relay address, and D20 email sent through Resend reaches the personal inbox.
- Later sign-in for the same Apple subject works when Apple omits first-consent name data and does not change the D20 email.
- An Apple email matching an existing D20 account does not authenticate or link automatically.
- A sudo-valid signed-in user can link Apple from Account Settings; ownership conflicts remain generic.
- Cancelled consent, invalid state or nonce, expired flow, malformed callback, token exchange failure, and disabled callbacks create no D20 session or identity.
- Successful login rotates the D20 session and accepts only safe local return paths.
- Removing the Apple runtime values prevents new Apple requests while email, password, and magic-link authentication remain available.

## Rollback

Remove the Apple runtime values and restart the release. Existing users and Apple identity rows remain intact, so those users can continue through any local method configured on their D20 account. No database rollback is required.
