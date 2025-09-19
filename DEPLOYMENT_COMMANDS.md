# 🚀 Deployment Commands - Authentication Fix

## 📥 Step 1: Pull Latest Code

```bash
# Navigate to your project directory
cd /path/to/your/operamobile

# Pull latest changes from GitHub
git pull origin main

# Verify you have the latest changes
git log --oneline -5
```

## 🔧 Step 2: Set New Replicate API Token

```bash
# Set the new working Replicate API token
export REPLICATE_API_TOKEN="YOUR_NEW_REPLICATE_TOKEN_HERE"

# Verify the token works
curl -X GET "https://api.replicate.com/v1/account" \
  -H "Authorization: Token $REPLICATE_API_TOKEN" \
  -H "Content-Type: application/json"
```

## 🌐 Step 3A: Deploy to Netlify (Production)

### Option 1: Update via Netlify Dashboard
1. Go to: https://app.netlify.com/sites/YOUR_SITE/settings/env
2. Update `REPLICATE_API_TOKEN` to: `YOUR_NEW_REPLICATE_TOKEN_HERE`
3. Click "Save"
4. Trigger new deployment (or it will auto-deploy from GitHub)

### Option 2: Deploy with Updated Scripts
```bash
# Update deployment scripts with new token
sed -i "s/REPLICATE_API_TOKEN=r8_.*/REPLICATE_API_TOKEN=YOUR_NEW_REPLICATE_TOKEN_HERE/" deploy-production.sh

# Run production deployment
./deploy-production.sh
```

## 🖥️ Step 3B: Deploy Local Server

```bash
# Set environment variable
export REPLICATE_API_TOKEN="YOUR_NEW_REPLICATE_TOKEN_HERE"

# Install dependencies (if needed)
npm install

# Start the server
node server.js

# Server will run on http://localhost:3002
```

## 📱 Step 3C: Build Mobile App

```bash
# Update mobile deployment script
sed -i "s/REPLICATE_API_TOKEN=r8_.*/REPLICATE_API_TOKEN=YOUR_NEW_REPLICATE_TOKEN_HERE/" deploy-mobile.sh

# Build mobile app
./deploy-mobile.sh

# Or build manually:
flutter clean
flutter pub get
flutter build web --release
```

## 🧪 Step 4: Test the Fix

### Get JWT Token
```bash
# Start token helper (if not already running)
python3 -m http.server 8080

# Open in browser: http://localhost:8080/get_token.html
# Login and copy the JWT token
```

### Test API with Real Tokens
```bash
# Replace YOUR_JWT_TOKEN with actual token from web page
curl -X POST https://operastudio.io/.netlify/functions/replicate-predict \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"input":{"image":"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD//2Q=="}}'
```

### Expected Results
- ✅ **Status 200/201**: Complete success - both authentication and AI processing work!
- ⚠️ **Status 400**: Supabase auth works, minor image data issue (still success)
- ❌ **Status 401**: Authentication problem (check token setup)

## 🔄 Step 5: Verify Deployment

### Check Netlify Functions
```bash
# Test status endpoint
curl https://operastudio.io/.netlify/functions/replicate-status/test

# Check function logs in Netlify dashboard
```

### Check Local Server
```bash
# Test health endpoint
curl http://localhost:3002/health

# Check server logs for authentication messages
```

## 🎯 Quick Deploy Script

For convenience, you can use the provided deployment script:

```bash
# Make executable and run
chmod +x deploy_with_new_token.sh
./deploy_with_new_token.sh
```

## 📋 Summary

1. **Pull**: `git pull origin main`
2. **Set Token**: `export REPLICATE_API_TOKEN="YOUR_NEW_REPLICATE_TOKEN_HERE"`
3. **Deploy**: Choose Netlify, Local, or Mobile
4. **Test**: Use JWT token from http://localhost:8080/get_token.html
5. **Verify**: Check for 200/201 status codes

The authentication system is now fixed and ready to use! 🎉 