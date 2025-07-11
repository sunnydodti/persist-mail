# PersistMail API Documentation

This Bruno collection contains comprehensive API documentation for the PersistMail temporary email service.

## Overview

PersistMail is a temporary email service that provides disposable email addresses for testing, privacy, and development purposes. The API is built with FastAPI and integrates with Mailcow for robust email management.

## Collection Structure

### 📋 Health Check
- **Health Check** - Verify API status
- **Get Root** - API welcome message

### 📧 Emails
- **Get Emails** - Retrieve emails for a mailbox
- **Get Email Detail** - Get detailed email content with attachments

### 🌐 Domains
- **Get Available Domains** - List all active domains

### 📮 Mailbox Management (Mailcow Integration)
- **Create Temporary Mailbox** - Create new mailbox with Mailcow
- **Get Mailbox Info** - Retrieve mailbox details and usage
- **Extend Mailbox Expiry** - Extend expiration (premium feature)
- **Delete Mailbox** - Remove mailbox immediately

### 👤 User Management
- **Create User Account** - Register new user
- **User Login** - Authenticate and get token
- **Get User Profile** - View profile and subscription details

### 💳 Subscriptions
- **Get Subscription Plans** - List available plans
- **Subscribe to Plan** - Upgrade to premium
- **Cancel Subscription** - Cancel premium subscription

### 🔧 Admin
- **Create Domain** - Add new email domain
- **Update Domain** - Modify domain configuration
- **Delete Domain** - Remove domain
- **Get All Domains (Admin)** - List all domains (admin only)

### 📊 Analytics
- **Get Usage Statistics** - User usage analytics
- **Get System Status** - Public system metrics

## Environment Variables

Configure the following variables in your Bruno environment:

```
api_base: http://127.0.0.1:8000
access_token: (set after login)
admin_token: (admin authentication token)
test_email: test@temp.example.com
test_domain: temp.example.com
```

## Authentication

### User Authentication
1. Register: `POST /api/v1/users/register`
2. Login: `POST /api/v1/users/login`
3. Use the returned `access_token` in Authorization header: `Bearer {token}`

### API Key Authentication
For programmatic access, use the API key from your user profile:
```
Authorization: Bearer {api_key}
```

## Service Tiers

### Free Tier
- 25 emails per request
- 24-hour retention
- Public domains only
- Rate limited (60 req/min)
- Ads displayed

### Premium Tier ($4.99/month)
- 50 emails per request
- 72-hour retention
- Premium domains access
- Higher rate limits (1000 req/min)
- Ad-free experience
- Priority support

### Professional Tier ($9.99/month)
- 100 emails per request
- 168-hour retention (7 days)
- Custom domain support
- Highest rate limits (5000 req/min)
- Priority support

## Mailcow Integration Features

The service integrates with Mailcow for:
- Real-time mailbox creation
- Individual mailbox authentication
- Quota management
- Automatic cleanup
- Professional email handling

## Rate Limiting

- **Anonymous users**: 60 requests per minute
- **Free tier**: 60 requests per minute
- **Premium tier**: 1000 requests per minute
- **Professional tier**: 5000 requests per minute

## Error Handling

All endpoints return consistent error responses:

```json
{
  "detail": "Error description",
  "error_code": "SPECIFIC_ERROR_CODE",
  "timestamp": "2025-07-11T15:00:00Z"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Rate Limited
- `500` - Server Error

## Development Setup

1. Set the `api_base` URL to your local development server
2. Use the test endpoints to verify functionality
3. Register a test user for authenticated endpoints
4. Configure Mailcow integration for mailbox management

## Production URLs

- **API Base**: `https://api.persistmail.com`
- **Web Interface**: `https://persistmail.com`
- **Status Page**: `https://status.persistmail.com`

## Support

- **Documentation**: [docs.persistmail.com](https://docs.persistmail.com)
- **Support Email**: support@persistmail.com
- **Discord**: [discord.gg/persistmail](https://discord.gg/persistmail)

## Security

- All communication over HTTPS in production
- JWT tokens for authentication
- Individual mailbox passwords
- Rate limiting protection
- Input validation and sanitization

---

*Last updated: July 11, 2025*
