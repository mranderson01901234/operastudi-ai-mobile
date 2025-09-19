# Digital Ocean Deployment Instructions

## 🚀 Quick Deployment

Follow these steps on your **Digital Ocean server** to deploy the mobile app with the proper Git workflow:

### 1. Set Environment Variables
```bash
export REPLICATE_API_TOKEN=your_replicate_token_here
```

### 2. Run the Production Deployment Script
```bash
# If this is your first deployment:
sudo ./deploy-production.sh

# If you already have the repo cloned:
cd /var/www/operastudio-ai-mobile
sudo git pull origin main
sudo ./deploy-production.sh
```

## 📋 What the Script Does

1. **📥 Pulls latest code** from GitHub (proper Git workflow)
2. **📦 Installs dependencies** (Node.js, npm packages, Flutter dependencies)
3. **🏗️ Builds Flutter web app** with memory optimizations
4. **📁 Deploys web files** to `/var/www/operastudio-ai-static/mobile/`
5. **⚙️ Sets up API server** as systemd service (`operastudio-api`)
6. **🌐 Configures Nginx** reverse proxy for API endpoints
7. **🧪 Runs tests** to verify everything is working

## 🔧 Monitoring Commands

After deployment, use these commands to monitor your services:

```bash
# Check API server status
sudo systemctl status operastudio-api

# View real-time logs
sudo journalctl -u operastudio-api -f

# Restart API server if needed
sudo systemctl restart operastudio-api

# Test API endpoints
./test-api-endpoints.sh
```

## 🌐 Access Your App

- **Mobile App**: https://operastudio.io/mobile/
- **API Health Check**: https://operastudio.io/health

## 🔄 Future Deployments

For future updates, simply:

1. **On your local machine**: Make changes, commit, and push to GitHub
2. **On Digital Ocean server**: Run the deployment script again

```bash
cd /var/www/operastudio-ai-mobile
sudo ./deploy-production.sh
```

The script will:
- Pull the latest changes from GitHub
- Preserve your `.env` file
- Rebuild and redeploy everything
- Restart services as needed

## 🛠️ Troubleshooting

### If deployment fails:
1. Check system memory: `free -h`
2. Check disk space: `df -h`
3. View deployment logs in the terminal output
4. Check service logs: `sudo journalctl -u operastudio-api --lines=50`

### If mobile app doesn't load images:
1. Verify API server is running: `sudo systemctl status operastudio-api`
2. Test API endpoints: `./test-api-endpoints.sh`
3. Check Nginx configuration: `sudo nginx -t`

### Common Issues:
- **Low memory**: The script automatically creates swap space
- **Permission errors**: Make sure to run with `sudo`
- **Git conflicts**: The script resets to clean state automatically
- **Missing dependencies**: The script installs them automatically

## 📞 Support

If you encounter issues:
1. Check the deployment logs for specific error messages
2. Verify your `REPLICATE_API_TOKEN` is set correctly
3. Ensure your Digital Ocean server has at least 1GB RAM (2GB recommended)
4. Make sure ports 80, 443, and 3001 are accessible

The deployment script is designed to be idempotent - you can run it multiple times safely. 