#!/bin/bash

#========================
# 🛡️ Full Recon + XSS Script
# Author: [Your Name]
# GitHub: [your_github]
#========================

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

read -p "🔶 Enter your target domain (example.com): " DOMAIN

# Create workspace
WORKDIR="${DOMAIN}_recon"
mkdir -p $WORKDIR && cd $WORKDIR
echo -e "${GREEN}📁 Workspace created: $WORKDIR${NC}"

# 1️⃣ Subdomain Enumeration
echo -e "\n${RED}[1] Subdomain Enumeration...${NC}"
subfinder -d $DOMAIN -silent > subs1.txt
assetfinder --subs-only $DOMAIN >> subs1.txt
amass enum -passive -d $DOMAIN >> subs1.txt
cat subs1.txt | sort -u > subdomains.txt
rm subs1.txt
echo -e "${GREEN}✅ Subdomains saved to: subdomains.txt${NC}"

# 2️⃣ Live Subdomain Checking
echo -e "\n${RED}[2] Probing live subdomains...${NC}"
httpx -l subdomains.txt -silent -status-code -title > live.txt
cat live.txt | awk '{print $1}' > live_domains.txt
echo -e "${GREEN}✅ Live domains saved to: live_domains.txt${NC}"

# 3️⃣ URL Harvesting (Wayback + Gau)
echo -e "\n${RED}[3] Harvesting URLs from wayback & gau...${NC}"
for domain in $(cat live_domains.txt); do
  gau $domain >> gau.txt
  waybackurls $domain >> wayback.txt
done
cat gau.txt wayback.txt | sort -u > all-urls.txt
echo -e "${GREEN}✅ URLs saved to: all-urls.txt${NC}"

# 4️⃣ JavaScript File Extraction
echo -e "\n${RED}[4] Extracting JavaScript URLs...${NC}"
cat all-urls.txt | grep "\.js" | grep -vE "\.json|\.css" | sort -u > js-files.txt
echo -e "${GREEN}✅ JavaScript files saved to: js-files.txt${NC}"

# 5️⃣ JS Endpoint Extraction via LinkFinder
echo -e "\n${RED}[5] Analyzing JS files with LinkFinder...${NC}"
mkdir -p js-endpoints
for js in $(cat js-files.txt); do
  python3 ~/tools/LinkFinder/linkfinder.py -i $js -o cli >> js-endpoints/found.txt
done
echo -e "${GREEN}✅ JS endpoints saved to: js-endpoints/found.txt${NC}"

# 6️⃣ Parameter Discovery
echo -e "\n${RED}[6] Discovering parameters...${NC}"
paramspider -d $DOMAIN --exclude woff,ttf,png,jpg,jpeg,gif,svg --quiet -o paramspider.txt
cat all-urls.txt | gf xss >> gf-xss.txt
cat paramspider.txt gf-xss.txt | sort -u > xss-params.txt
echo -e "${GREEN}✅ Potential XSS parameters saved to: xss-params.txt${NC}"

# 7️⃣ DOM-Based XSS Sink Detection (KXSS)
echo -e "\n${RED}[7] DOM Sink Detection...${NC}"
cat xss-params.txt | kxss > dom-sinks.txt
echo -e "${GREEN}✅ DOM sinks saved to: dom-sinks.txt${NC}"

# 8️⃣ Active XSS Scanning with DalFox
echo -e "\n${RED}[8] Running DalFox XSS scan...${NC}"
dalfox file xss-params.txt --silence --skip-bav -o dalfox-results.txt
echo -e "${GREEN}✅ DalFox results saved to: dalfox-results.txt${NC}"

# 9️⃣ Blind XSS Setup Reminder
echo -e "\n${RED}[9] Reminder: For Blind XSS, set up XSS Hunter or interactsh.com listener.${NC}"

# ✅ Done
echo -e "\n${GREEN}🎯 Recon Complete! All results saved in: $WORKDIR${NC}"
