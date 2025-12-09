# Security Guide

This document provides guidelines and best practices for securing the Flutter Music Player application.

## Securing Sensitive Information

### Using Environment Variables

The application uses flutter_dotenv to manage sensitive information. The `.env` file contains:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
ADMIN_EMAIL=phamngocpho@duck.com
ADMIN_PASSWORD=your_secure_password
SONGS_BUCKET=songs
COVERS_BUCKET=song-covers
```

### Important Rules

1. **Never commit .env file to Git**
   - This file is already added to `.gitignore`
   - Only commit `.env.example` file (template)

2. **Each environment has its own file**
   - Development: `.env`
   - Staging: `.env.staging`
   - Production: `.env.production`

3. **Safe Backup**
   - Store in password manager (1Password, LastPass, Bitwarden)
   - Or use secure vault (AWS Secrets Manager, Azure Key Vault)
   - Do not store in email, chat, or notes app

## Admin Security

### Change Default Credentials

Default admin credentials are for development only. For production:

1. Change admin email in `.env`:
```env
ADMIN_EMAIL=your_real_admin@company.com
```

2. Create strong password:
   - Minimum 16 characters
   - Include uppercase, lowercase, numbers, special characters
   - Do not use dictionary words
   - Do not reuse passwords

### Hash Admin Password

Instead of storing plain text password in `.env`, use hashing:

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashPassword(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

// In .env
ADMIN_PASSWORD_HASH=hashed_password_here
```

### Multi-Factor Authentication

Consider enabling MFA for admin:
1. Go to Supabase Authentication settings
2. Enable MFA
3. Require admin to setup authenticator app

## Supabase Security

### API Keys

**Anon Key**
- Used for client-side
- Can be public but needs RLS protection
- Cannot perform admin operations

**Service Role Key**
- ABSOLUTELY do not expose to client
- Only use in backend/server-side
- Has permission to bypass RLS

### Row Level Security (RLS)

Always enable RLS for all tables:

```sql
ALTER TABLE public."TableName" ENABLE ROW LEVEL SECURITY;
```

Create specific policies:

```sql
-- Only allow users to view their own data
CREATE POLICY "Users see own data"
ON public."TableName"
FOR SELECT
USING (auth.uid() = user_id);
```

### Storage Security

**Bucket Policies**
- Control who can upload/download
- Limit file types
- Limit file size

**File Validation**
```dart
// Check file type
bool isValidAudioFile(String filename) {
  final validExtensions = ['.mp3', '.m4a', '.wav', '.flac'];
  return validExtensions.any((ext) => filename.toLowerCase().endsWith(ext));
}

// Check file size
bool isValidFileSize(int bytes) {
  const maxSize = 50 * 1024 * 1024; // 50MB
  return bytes <= maxSize;
}
```

## Authentication Security

### Password Policy

Enforce password requirements:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

### Session Management

**Timeout**
- Auto logout after 30 minutes of inactivity
- Refresh token before expiration

**Token Storage**
- Use secure storage
- Do not store in SharedPreferences plain text
- Encrypt tokens if possible

### Brute Force Protection

Limit login attempts:
```dart
int failedAttempts = 0;
const maxAttempts = 5;

if (failedAttempts >= maxAttempts) {
  // Temporarily lock account
  await lockAccount(duration: Duration(minutes: 15));
}
```

## Network Security

### HTTPS Only

Always use HTTPS:
```dart
// In Supabase config
static String get supabaseUrl {
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  if (!url.startsWith('https://')) {
    throw Exception('SUPABASE_URL must use HTTPS');
  }
  return url;
}
```

### Certificate Pinning

Consider implementing certificate pinning for production:
```dart
// In HTTP client config
SecurityContext securityContext = SecurityContext.defaultContext;
securityContext.setTrustedCertificates('path/to/certificates.pem');
```

## Data Security

### Encryption at Rest

Supabase automatically encrypts data at rest. For additional sensitive data:

```dart
import 'package:encrypt/encrypt.dart';

String encryptData(String plainText, String key) {
  final keyBytes = Key.fromUtf8(key);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(keyBytes));
  return encrypter.encrypt(plainText, iv: iv).base64;
}
```

### Data Validation

Validate all input:
```dart
String sanitizeInput(String input) {
  // Remove HTML tags
  input = input.replaceAll(RegExp(r'<[^>]*>'), '');
  // Remove SQL injection attempts
  input = input.replaceAll(RegExp(r"[;'\"]"), '');
  return input.trim();
}
```

## Code Security

### Obfuscation

Build with obfuscation:
```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Code Signing

**Android**
- Sign APK with private keystore
- Store keystore securely
- Do not commit keystore to Git

**iOS**
- Use Apple Developer certificates
- Setup correct provisioning profiles
- Enable app signing

### Dependencies

Check dependencies regularly:
```bash
flutter pub outdated
flutter pub upgrade --major-versions
```

Audit security vulnerabilities:
```bash
dart pub audit
```

## Monitoring and Logging

### Error Tracking

Integrate error tracking:
```dart
try {
  // Sensitive operation
} catch (e) {
  // Log error but do not expose sensitive data
  logger.error('Operation failed', error: e.toString());
  // Do not log passwords, tokens, etc.
}
```

### Audit Logs

Log important events:
- User login/logout
- Admin operations (add/edit/delete songs)
- Failed authentication attempts
- Permission denied errors

```dart
void logAdminAction(String action, String userId, Map<String, dynamic> details) {
  final log = {
    'timestamp': DateTime.now().toIso8601String(),
    'action': action,
    'userId': userId,
    'details': details,
  };
  // Send to logging service
}
```

## Security Headers

If deploying web, configure security headers:

```
Content-Security-Policy: default-src 'self'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## Backup and Recovery

### Backup Strategy

1. **Database Backups**
   - Daily automated backups
   - Retain 30 days
   - Test restore procedure

2. **Storage Backups**
   - Backup files to separate location
   - Verify integrity

3. **Config Backups**
   - Backup `.env` files securely
   - Document all configurations

### Disaster Recovery Plan

1. Identify critical data
2. Define Recovery Time Objective (RTO)
3. Define Recovery Point Objective (RPO)
4. Test recovery procedures quarterly

## Security Checklist

### Development
- [ ] `.env` file not committed
- [ ] Dependencies up to date
- [ ] No hardcoded secrets
- [ ] Input validation implemented
- [ ] Error handling proper

### Pre-Production
- [ ] Changed default admin credentials
- [ ] RLS policies tested
- [ ] Storage policies configured
- [ ] HTTPS enforced
- [ ] Security headers set

### Production
- [ ] Strong passwords used
- [ ] MFA enabled for admin
- [ ] Monitoring setup
- [ ] Backup strategy active
- [ ] Incident response plan ready
- [ ] Regular security audits scheduled

## Incident Response

### If Breached

1. **Immediate Actions**
   - Rotate all credentials immediately
   - Revoke compromised tokens
   - Lock affected accounts

2. **Investigation**
   - Review audit logs
   - Identify breach vector
   - Assess impact

3. **Containment**
   - Patch vulnerabilities
   - Update security policies
   - Notify affected users if necessary

4. **Recovery**
   - Restore from clean backup
   - Verify system integrity
   - Monitor for suspicious activity

### Reporting Security Issues

If you discover a security vulnerability:
1. DO NOT create a public issue
2. Email privately to: security@yourcompany.com
3. Provide details to reproduce
4. Give the team 90 days to fix before going public

## Best Practices Summary

1. **Principle of Least Privilege**
   - Only grant minimum necessary permissions
   - Review permissions regularly

2. **Defense in Depth**
   - Multiple layers of security
   - Do not rely on a single point

3. **Security by Design**
   - Consider security from the start
   - Do not bolt-on afterwards

4. **Regular Updates**
   - Update dependencies monthly
   - Patch security vulnerabilities immediately

5. **Education**
   - Train team on security
   - Stay updated with new threats

## Compliance

If the app processes user data:
- GDPR (EU users)
- CCPA (California users)
- Local data protection laws

Implement:
- User data export
- Right to deletion
- Privacy policy
- Terms of service

## Useful Tools

**Security Scanning**
- OWASP Dependency Check
- Snyk
- GitGuardian (scan secrets in Git)

**Penetration Testing**
- Burp Suite
- OWASP ZAP
- Nmap

**Monitoring**
- Sentry (error tracking)
- LogRocket (session replay)
- Datadog (infrastructure monitoring)

## Reference Documentation

- OWASP Mobile Security: https://owasp.org/www-project-mobile-top-10/
- Flutter Security: https://docs.flutter.dev/security
- Supabase Security: https://supabase.com/docs/guides/auth/security
- NIST Guidelines: https://www.nist.gov/cybersecurity

## Document Updates

This document should be reviewed and updated:
- Quarterly
- After each security incident
- When new threats emerge
- When architecture changes

---

**Note**: Security is an ongoing process, not a one-time task. Always be vigilant and proactive about security.

