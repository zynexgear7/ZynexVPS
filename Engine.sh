#!/bin/bash
set -euo pipefail

# =============================================
# ZYNEX ENGINE VPS CORE SCRIPT (Premium)
# Version: 1.1 (Branded)
# =============================================

# -----------------------------
# Colors
# -----------------------------
ORANGE="\e[38;5;208m"
CYAN="\e[36m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

clear

# -----------------------------
# Small ZYNEX Banner
# -----------------------------
echo -e "${ORANGE}"
echo "  ______ __     __  _   _   ______  __   __  "
echo " |___  / \ \   / / | \ | | |  ____| \ \ / /  "
echo "    / /   \ \_/ /  |  \| | | |__     \ V /   "
echo "   / /     \   /   | . \` | |  __|     > <    "
echo "  / /__     | |    | |\  | | |____   / . \   "
echo " /_____|    |_|    |_| \_| |______| /_/ \_\  "
echo "                                             "
echo -e "${CYAN}           ⚡ Z Y N E X ⚡${RESET}\n"

# -----------------------------
# Firebase placeholder logic
# -----------------------------
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_KEY_FILE="/opt/zynexengine/firebase-key.json"

if [ ! -f "$FIREBASE_KEY_FILE" ]; then
    echo -e "${RED}❌ Firebase key missing at $FIREBASE_KEY_FILE${RESET}"
    echo -e "${CYAN}🔹 Skipping Firebase connection (replace with your key)${RESET}"
else
    echo -e "${CYAN}⚡ Connecting to Firebase project $FIREBASE_PROJECT_ID…${RESET}"
    export GOOGLE_APPLICATION_CREDENTIALS="$FIREBASE_KEY_FILE"
    node -e "const admin = require('firebase-admin'); const serviceAccount = require('$FIREBASE_KEY_FILE'); admin.initializeApp({credential: admin.credential.cert(serviceAccount)}); console.log('Firebase ready!');"
fi

# -----------------------------
# VPS creation / simulation
# -----------------------------
echo -e "${GREEN}✅ VPS instance simulated/created successfully!${RESET}"

# -----------------------------
# Keep the engine running (24/7)
# -----------------------------
while true; do
    echo -e "${CYAN}🔹 Zynex Engine running… $(date)${RESET}"
    sleep 60
done
