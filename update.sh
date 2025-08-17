#!/bin/bash

set -e

# Step 1: Remove old launcher
echo "[*] Removing old launcher from /usr/local/bin..."
sudo rm -f /usr/local/bin/burpsuitepro

# Step 2: Install dependencies
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y git axel curl grep sed openjdk-21-jre

# Step 3: Clone repo
echo "[*] Cloning updated repo..."
rm -rf Burpsuite-Professional-Updated 2>/dev/null
git clone https://github.com/ghostvirus62/Burpsuite-Professional-Updated.git
cd Burpsuite-Professional-Updated || { echo "[-] Failed to cd into repo"; exit 1; }

# Step 4: Set hardcoded version
version="2025.8.1"
jar_file="burpsuite_pro_v$version.jar"
jar_url="https://portswigger-cdn.net/burp/releases/download?product=pro&version=$version&type=Jar"

# Step 5: Download Burp JAR
echo "[*] Downloading $jar_file..."
axel -n 8 -o "$jar_file" "$jar_url" || curl -L "$jar_url" -o "$jar_file"

# Step 6: Sanity check
if file "$jar_file" | grep -q 'HTML'; then
    echo "[-] ERROR: Downloaded file is HTML, not a JAR. Version or URL might be incorrect."
    exit 1
fi

# Step 7: Start loader
if [[ ! -f loader.jar ]]; then
    echo "[-] ERROR: loader.jar not found in repo."
    exit 1
fi

echo "[*] Starting loader.jar..."
(java -jar loader.jar) &

# Step 8: Create launcher
echo "[*] Creating launcher script..."
cat <<EOF > burpsuitepro
#!/bin/bash
java \\
--add-opens=java.desktop/javax.swing=ALL-UNNAMED \\
--add-opens=java.base/java.lang=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \\
--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \\
-javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/$jar_file &
EOF

chmod +x burpsuitepro
sudo cp burpsuitepro /usr/local/bin/burpsuitepro

# Step 9: Launch Burp
echo "[*] Launching Burp Suite Pro v$version..."
./burpsuitepro
