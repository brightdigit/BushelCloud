#!/bin/bash
# Add environment variables from .env to Xcode scheme

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME_FILE="${PROJECT_DIR}/.swiftpm/xcode/xcshareddata/xcschemes/bushel-cloud.xcscheme"
TEMP_FILE="${SCHEME_FILE}.new"

if [ ! -f "${PROJECT_DIR}/.env" ]; then
    echo "❌ No .env file found"
    exit 1
fi

if [ ! -f "${SCHEME_FILE}" ]; then
    echo "❌ Scheme not found"
    exit 1
fi

echo "✅ Found scheme and .env file"
echo ""
echo "📝 Adding environment variables:"

# Backup
cp "${SCHEME_FILE}" "${SCHEME_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Create temp file with new variables
ENV_XML_FILE=$(mktemp)

while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # Check if already exists
    if grep -q "key = \"$key\"" "${SCHEME_FILE}"; then
        echo "   ⏭️  $key (already exists)"
        continue
    fi

    # Remove quotes and expand $HOME etc
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//" | envsubst)

    # Escape XML entities
    value=$(echo "$value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

    # Write XML for this variable
    cat >> "$ENV_XML_FILE" << EOF
         <EnvironmentVariable
            key = "${key}"
            value = "${value}"
            isEnabled = "YES">
         </EnvironmentVariable>
EOF

    echo "   ✅ $key"
done < "${PROJECT_DIR}/.env"

# Check if we have anything to add
if [ ! -s "$ENV_XML_FILE" ]; then
    echo ""
    echo "ℹ️  No new variables to add"
    rm "$ENV_XML_FILE"
    exit 0
fi

# Insert the variables before </EnvironmentVariables> using perl
perl -i.bak -pe "
    if (m|</EnvironmentVariables>|) {
        open(my \$fh, '<', '$ENV_XML_FILE');
        my \$xml = do { local \$/; <\$fh> };
        close(\$fh);
        print \$xml;
    }
" "${SCHEME_FILE}"

rm -f "${SCHEME_FILE}.bak" "$ENV_XML_FILE"

echo ""
echo "🎉 Done! Environment variables added to scheme"
