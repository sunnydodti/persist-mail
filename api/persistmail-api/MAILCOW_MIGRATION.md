# PersistMail API - Mailcow Integration

## Overview

PersistMail has been refactored to work with Mailcow, a modern mail server solution. This document outlines the changes and how to configure the system.

## What Changed

### 1. Mailcow Integration
- **New Mailcow API Client**: Direct integration with Mailcow's REST API
- **Individual Mailbox Passwords**: Each temporary mailbox gets a unique password
- **Automatic Mailbox Creation**: Mailboxes are created via API calls instead of SMTP
- **Proper Lifecycle Management**: Mailboxes are automatically cleaned up when expired

### 2. Database Schema Updates
- Added `password` field to store individual mailbox passwords
- Added `quota_mb` and `quota_used_mb` for quota tracking
- Added `expires_at` for automatic expiration
- Added `mailcow_managed` flag to distinguish between Mailcow and legacy mailboxes
- Added `is_mailcow_managed` flag to domains

### 3. New Features
- **Random Mailbox Generation**: `/api/v1/mailbox/random` endpoint
- **Mailbox Information**: `/api/v1/mailbox/{email}/info` endpoint
- **Automatic Cleanup**: Background service to clean expired mailboxes
- **Quota Monitoring**: Track and update mailbox usage
- **Health Checks**: Monitor Mailcow API connectivity

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Mailcow Settings (REQUIRED)
MAILCOW_API_URL=https://mail.yourdomain.com
MAILCOW_API_KEY=your-mailcow-api-key-here
MAILCOW_DOMAIN=yourdomain.com

# Mailbox Settings
DEFAULT_MAILBOX_QUOTA=50        # MB
MAILBOX_EXPIRY_HOURS=24         # Hours before auto-cleanup
PASSWORD_LENGTH=16              # Generated password length
```

### Mailcow API Key

1. Login to your Mailcow admin panel
2. Go to **Configuration > Access > REST API**
3. Create a new API key with the following permissions:
   - Mailboxes: Read, Write, Delete
   - Domains: Read
   - System: Read (for health checks)

## New API Endpoints

### User Endpoints

1. **Create Random Mailbox**
   ```
   POST /api/v1/mailbox/random?domain=yourdomain.com
   ```
   
2. **Get Mailbox Info**
   ```
   GET /api/v1/mailbox/{email}/info
   ```

### Admin Endpoints

3. **List All Mailboxes**
   ```
   GET /api/v1/admin/mailboxes?domain=yourdomain.com&active_only=true
   ```

4. **Delete Specific Mailbox**
   ```
   DELETE /api/v1/admin/mailboxes/{email}
   ```

5. **Cleanup Operations**
   ```
   POST /api/v1/admin/cleanup/expired
   POST /api/v1/admin/cleanup/inactive?hours=72
   POST /api/v1/admin/quota/update
   ```

6. **Health Check**
   ```
   GET /api/v1/admin/health/mailcow
   ```

## Background Services

### Cleanup Service

The cleanup service runs automatically and performs:

- **Expired Mailbox Cleanup**: Removes mailboxes past their expiration time
- **Inactive Mailbox Cleanup**: Removes mailboxes not accessed for 72+ hours
- **Quota Updates**: Syncs quota usage from Mailcow

Run manually:
```python
python -m app.services.cleanup_service
```

## Migration from Legacy Setup

### For Existing Domains

1. **Update Domain Configuration**:
   - Set `is_mailcow_managed=true` for domains hosted on Mailcow
   - Set `credentials_key=null` for Mailcow domains (not needed)

2. **Database Migration**:
   - Existing mailboxes will continue to work with shared credentials
   - New mailboxes will use individual passwords
   - The system supports both modes simultaneously

### Domain Setup Example

```python
# Add Mailcow domain
POST /api/v1/admin/domains
{
    "domain": "yourdomain.com",
    "imap_host": "mail.yourdomain.com",
    "imap_port": 993,
    "is_premium": false,
    "is_mailcow_managed": true
}
```

## Backward Compatibility

- **Legacy Domains**: Continue to work with shared credentials
- **Mixed Environment**: Can run both Mailcow and legacy domains
- **Gradual Migration**: Migrate domains one by one

## Security Improvements

1. **Individual Passwords**: Each mailbox has a unique, secure password
2. **Automatic Cleanup**: Expired mailboxes are automatically removed
3. **Quota Limits**: Prevents abuse through quota enforcement
4. **API Key Management**: Secure communication with Mailcow

## Monitoring

### Health Checks

- **API Health**: `GET /health`
- **Mailcow Connectivity**: `GET /api/v1/admin/health/mailcow`

### Logs

Monitor the application logs for:
- Mailbox creation/deletion events
- Cleanup operations
- API connectivity issues
- IMAP authentication failures

## Troubleshooting

### Common Issues

1. **Mailcow API Connection Failed**
   - Verify `MAILCOW_API_URL` is correct
   - Check API key permissions
   - Ensure network connectivity

2. **Domain Not Found in Mailcow**
   - Add domain to Mailcow first
   - Verify domain is active in Mailcow

3. **IMAP Authentication Failed**
   - Check if mailbox exists in Mailcow
   - Verify password is correct
   - Check IMAP server settings

### Debug Mode

Enable debug logging by setting:
```bash
LOG_LEVEL=DEBUG
```

## Performance Considerations

- **Cleanup Frequency**: Runs every hour by default
- **API Rate Limits**: Mailcow API has built-in rate limiting
- **Database Indexing**: Indexes on email and domain fields
- **Connection Pooling**: HTTP client uses connection pooling

## Future Enhancements

- **Redis Caching**: Cache mailbox passwords and quota info
- **Webhooks**: Real-time notifications from Mailcow
- **Advanced Quotas**: Per-domain quota limits
- **Analytics**: Usage statistics and metrics
