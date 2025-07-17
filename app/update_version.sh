#!/bin/bash

# --- Configuration ---
APP_DIR="app"
BUILD_FILE="build.gradle.kts"
COMMIT_MESSAGE="Bumped up version"

# --- Helper Functions ---
get_version_code() {
  grep "versionCode" "$APP_DIR/$BUILD_FILE" | awk -F'= ' '{print $2}'
}

get_version_name() {
  grep "versionName" "$APP_DIR/$BUILD_FILE" | awk -F'= "' '{print $2}' | sed 's/"//g'
}

set_version_code() {
  local new_code="$1"
  # macOS-compatible sed syntax
  sed -i '' "s/versionCode = .*/versionCode = $new_code/" "$APP_DIR/$BUILD_FILE"
}

set_version_name() {
  local new_name="$1"
  # macOS-compatible sed syntax
  sed -i '' "s/versionName = \".*\"/versionName = \"$new_name\"/" "$APP_DIR/$BUILD_FILE"
}

# --- Script Execution ---
echo "📦 Starting version update..."

if [ "$PWD" != */$APP_DIR ]; then
  cd "$APP_DIR" || { echo "❌ Failed to navigate to $APP_DIR"; exit 1; }
fi

# Step 2: Read current versionCode
current_code=$(get_version_code)
echo "🔢 Current versionCode: $current_code"

# Step 3: Increment versionCode
new_code=$((current_code + 1))
set_version_code "$new_code"
echo "✅ Updated versionCode to: $new_code"

# Step 4: Read current versionName
current_name=$(get_version_name)
echo "🔤 Current versionName: $current_name"

# Step 5: Prompt for new versionName
read -p "✏️  Enter new versionName: " new_name
if [[ -z "$new_name" ]]; then
  echo "❌ versionName cannot be empty"
  exit 1
fi
set_version_name "$new_name"
echo "✅ Updated versionName to: $new_name"

# Step 6: Stage changes
git add "$BUILD_FILE"
echo "📁 Staged changes to $BUILD_FILE"

# Step 7: Go back to root
cd .. || exit 1

# Step 8: Commit
git commit -m "$COMMIT_MESSAGE: $current_name → $new_name"
echo "📝 Committed changes"

# Step 9: Tag
if git rev-parse "$new_name" >/dev/null 2>&1; then
  echo "⚠️ Tag '$new_name' already exists. Skipping tagging."
else
  git tag "$new_name"
  echo "🏷️ Tagged with: $new_name"
fi

# Step 10: Push
git push origin HEAD && git push origin "$new_name"
echo "🚀 Pushed changes and tag"

echo "🎉 Version update complete!"
