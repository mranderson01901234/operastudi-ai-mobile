# 🔍 Mobile Deployment Image Upload Failure - Comprehensive Diagnostic Prompt

**Date:** September 19, 2025  
**Purpose:** Gather complete configuration and state information for mobile image upload troubleshooting  
**Priority:** 🔴 **CRITICAL** - Production deployment failing

---

## 📋 **DIAGNOSTIC INFORMATION REQUEST**

I need you to provide comprehensive information about the current web application environment and mobile deployment configuration. The mobile app is failing to upload/process images after successful authentication, and we need to identify all potential configuration mismatches or service issues.

---

## 🔧 **1. NETLIFY FUNCTIONS STATUS & CONFIGURATION**

### 1.1 Function Deployment Status
Please provide the current status of ALL Netlify functions:

```bash
# Run these commands and provide output:
netlify functions:list
netlify functions:invoke replicate-predict --no-identity
netlify functions:invoke replicate-status --no-identity  
netlify functions:invoke api-v1-enhance-general --no-identity
```

**Required Information:**
- ✅ Which functions are currently deployed and active?
- ✅ What are the current function sizes and build status?
- ✅ Are there any deployment errors or warnings?
- ✅ What are the function timeout settings?

### 1.2 Function Environment Variables
For each active function, please verify these environment variables are set:

**Critical Variables:**
- `SUPABASE_URL` = `https://rnygtixdxbnflxflzpyr.supabase.co`
- `SUPABASE_ANON_KEY` = `sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3`
- `SUPABASE_SERVICE_ROLE_KEY` = `[SERVICE_KEY]`
- `REPLICATE_API_TOKEN` = `[REPLICATE_TOKEN]`
- `NETLIFY_URL` = `[NETLIFY_DEPLOYMENT_URL]`

**Command to check:**
```bash
netlify env:list
```

### 1.3 Function Payload Limits
**Current Netlify Settings:**
- Function timeout: `?` seconds
- Function memory: `?` MB
- Payload size limit: `?` MB
- Background function enabled: `?`

---

## 🌐 **2. SUPABASE CONFIGURATION STATUS**

### 2.1 Database Schema Validation
Please verify these critical tables and policies exist:

**Users Table:**
```sql
-- Run in Supabase SQL Editor:
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'users';
```

**Processing History Table:**
```sql
-- Check if processing_history table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'processing_history' 
ORDER BY ordinal_position;
```

**Storage Bucket:**
```sql
-- Check user-images bucket
SELECT id, name, public FROM storage.buckets WHERE id = 'user-images';

-- Check storage policies
SELECT bucket_id, name, definition 
FROM storage.policies 
WHERE bucket_id = 'user-images';
```

### 2.2 Authentication Configuration
**JWT Settings:**
- JWT expiry time: `?` hours
- JWT secret rotation: `?`
- Refresh token settings: `?`

**Auth Providers Enabled:**
- Email/Password: `?`
- OAuth providers: `?`
- Anonymous sign-ins: `?`

---

## 🔌 **3. API ENDPOINT CONNECTIVITY**

### 3.1 Direct Endpoint Testing
Please test each endpoint directly and provide the results:

**Test Commands:**
```bash
# Test 1: Replicate Predict Endpoint
curl -X POST https://operastudio.io/.netlify/functions/replicate-predict \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [VALID_JWT_TOKEN]" \
  -d '{"input":{"image":"data:image/jpeg;base64,/9j/4AAQSkZJRg...","scale":2,"sharpen":45,"denoise":30,"face_recovery":false}}'

# Test 2: Status Check Endpoint  
curl -X GET https://operastudio.io/.netlify/functions/replicate-status/[PREDICTION_ID] \
  -H "Content-Type: application/json"

# Test 3: General Enhancement Endpoint
curl -X POST https://operastudio.io/.netlify/functions/api-v1-enhance-general \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer [VALID_JWT_TOKEN]" \
  -F "image=@test_image.jpg" \
  -F "scale=2" \
  -F "sharpen=45"
```

**Required Response Information:**
- HTTP status codes returned
- Response headers (especially CORS headers)
- Response body content
- Response time/latency
- Any error messages

### 3.2 CORS Configuration Verification
**Current CORS Settings:**
```javascript
// From netlify functions - please verify:
const headers = {
  'Access-Control-Allow-Origin': '*',  // Is this correct?
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400'
};
```

---

## 📱 **4. MOBILE-SPECIFIC CONFIGURATION**

### 4.1 Mobile API Request Format
The mobile app sends requests in this format - please verify compatibility:

**Authentication Header:**
```
Authorization: Bearer [SUPABASE_JWT_TOKEN]
```

**Request Body Format (JSON):**
```json
{
  "input": {
    "image": "data:image/jpeg;base64,[BASE64_STRING]",
    "scale": 2,
    "sharpen": 45,
    "denoise": 30,
    "face_recovery": false
  }
}
```

**Questions:**
- Does the web API expect this exact JSON structure?
- Are parameter names case-sensitive?
- Is `face_recovery` vs `faceRecovery` causing issues?
- What's the maximum base64 string size accepted?

### 4.2 Image Processing Constraints
**Mobile Image Specifications:**
- Maximum dimensions: `2048x2048` pixels
- Image quality: `90%` JPEG
- Supported formats: `JPEG, PNG, HEIC, WebP`
- Maximum file size before encoding: `10MB`
- Maximum base64 payload: `~6MB` (after encoding)

**Compatibility Questions:**
- Does the web API support these image specifications?
- Are there server-side size limits that might be exceeded?
- Is HEIC format properly handled by the web functions?

---

## 🔐 **5. AUTHENTICATION FLOW VALIDATION**

### 5.1 JWT Token Validation
Please verify a mobile-generated JWT token:

**Token Example (from mobile app):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzI2NzY4MjEwLCJpYXQiOjE3MjY3NjQ2MTAsImlzcyI6Imh0dHBzOi8vcm55Z3RpeGR4Ym5mbHhmbHpweXIuc3VwYWJhc2UuY28vYXV0aC92MSIsInN1YiI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCIsImVtYWlsIjoiYWRtaW5AZXhhbXBsZS5jb20iLCJwaG9uZSI6IiIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIiwicHJvdmlkZXJzIjpbImVtYWlsIl19LCJ1c2VyX21ldGFkYXRhIjp7fSwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJhYWwiOiJhYWwxIiwiYW1yIjpbeyJtZXRob2QiOiJwYXNzd29yZCIsInRpbWVzdGFtcCI6MTcyNjc2NDYxMH1dLCJzZXNzaW9uX2lkIjoiMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwIn0.example_signature
```

**Validation Commands:**
```bash
# Decode JWT payload
echo "eyJhdWQiOiJhdXRoZW50aWNhdGVkIi..." | base64 -d

# Test token with Supabase
curl -X GET https://rnygtixdxbnflxflzpyr.supabase.co/auth/v1/user \
  -H "Authorization: Bearer [JWT_TOKEN]" \
  -H "apikey: sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3"
```

### 5.2 Session Management
**Questions:**
- What's the current JWT expiry time?
- Are refresh tokens working properly?
- Is there automatic session renewal?
- Are there any rate limits on authentication?

---

## 🚨 **6. ERROR TRACKING & MONITORING**

### 6.1 Recent Error Logs
Please provide logs from the last 24 hours for:

**Netlify Function Logs:**
```bash
netlify logs:functions --filter="replicate-predict"
netlify logs:functions --filter="replicate-status"  
netlify logs:functions --filter="api-v1-enhance-general"
```

**Supabase Logs:**
- Authentication failures
- Database query errors
- Storage upload failures
- RLS policy violations

### 6.2 Specific Error Patterns
Look for these specific error patterns in logs:

**Authentication Errors:**
- `"Invalid token"`
- `"User not authenticated"`
- `"JWT expired"`
- `"Session not found"`

**Processing Errors:**
- `"Image too large"`
- `"Invalid image format"`
- `"Processing timeout"`
- `"Replicate API error"`

**Database Errors:**
- `"Row-level security policy violation"`
- `"Permission denied"`
- `"Table does not exist"`

---

## 📊 **7. PERFORMANCE & RESOURCE MONITORING**

### 7.1 Current Resource Usage
**Netlify Functions:**
- Function invocations (last 24h): `?`
- Average execution time: `?` ms
- Error rate: `?%`
- Timeout rate: `?%`

**Supabase:**
- Database connections: `?`
- Storage usage: `?` GB
- Auth API calls: `?`
- Bandwidth usage: `?` GB

### 7.2 Rate Limiting Status
**Current Limits:**
- Netlify function calls: `?` per minute
- Supabase API calls: `?` per minute
- Replicate API calls: `?` per minute
- Storage uploads: `?` per minute

---

## 🔄 **8. DEPLOYMENT & BUILD STATUS**

### 8.1 Latest Deployment Information
**Netlify Deployment:**
- Last successful deploy: `?`
- Build status: `?`
- Build time: `?`
- Any build warnings/errors: `?`

**Environment Variables Changed:**
- When were environment variables last updated?
- Are all required variables present?
- Any recent changes to Supabase keys?

### 8.2 Version Compatibility
**Current Versions:**
- Node.js version: `?`
- Netlify CLI version: `?`
- Function runtime: `?`
- Dependencies updated: `?`

---

## 🎯 **9. SPECIFIC MOBILE FAILURE SCENARIOS**

Based on our analysis, these are the exact failure points. Please test these scenarios:

### 9.1 Scenario 1: Authentication State Loss
**Test Steps:**
1. Mobile user successfully logs in
2. User navigates to image selection
3. User selects image and navigates to editing screen
4. User taps "Enhance" button
5. **FAILURE POINT:** API call returns "User not authenticated"

**Questions:**
- Is the JWT token being properly received by the web functions?
- Are there any middleware that might be stripping the Authorization header?
- Is session validation working correctly?

### 9.2 Scenario 2: Image Processing Stuck
**Test Steps:**
1. Mobile user successfully starts image enhancement
2. Processing begins (prediction ID returned)
3. Status polling starts
4. **FAILURE POINT:** Status never changes from "starting" to "completed"

**Questions:**
- Are status check endpoints returning proper responses?
- Is the Replicate API integration working?
- Are there any timeouts causing processing to fail silently?

### 9.3 Scenario 3: HEIC File Processing
**Test Steps:**
1. iPhone user selects HEIC image from Photos
2. Mobile app converts to base64
3. API call is made
4. **POTENTIAL FAILURE:** HEIC format not supported by web functions

**Questions:**
- Does the web API properly handle HEIC images?
- Is there server-side image format conversion?
- Are there any format-specific processing errors?

---

## 📝 **10. IMMEDIATE ACTION ITEMS**

Based on the provided information, I will be able to:

1. **Identify Configuration Mismatches** between mobile and web environments
2. **Diagnose Authentication Issues** causing "user not authenticated" errors
3. **Resolve API Endpoint Problems** preventing image processing
4. **Fix Session Management Issues** causing authentication state loss
5. **Optimize Image Processing Pipeline** for mobile-specific requirements

**Critical Questions:**
- Are you seeing any specific error messages in the Netlify function logs?
- Has anything changed in the web environment recently?
- Are other web clients (browser-based) working correctly?
- What's the current success rate for image processing from web clients?

---

## 🚀 **EXPECTED OUTCOMES**

After reviewing this diagnostic information, I will provide:

1. **Root Cause Analysis** of the image upload failures
2. **Specific Configuration Fixes** required
3. **Code Changes** needed in mobile or web components  
4. **Testing Protocol** to verify fixes
5. **Monitoring Setup** to prevent future issues

**Time to Resolution:** 2-4 hours after receiving complete diagnostic information

---

**Please provide as much of this information as possible, prioritizing sections 1-3 for immediate troubleshooting.** 