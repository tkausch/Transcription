#!/bin/bash

APP_NAME="TranscriptionApp"
BUNDLE_ID="com.yourcompany.TranscriptionApp"

echo "Removing $APP_NAME..."

# Delete app from Applications
sudo rm -rf "/Applications/$APP_NAME.app"

# Delete from DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/$APP_NAME-*/

# Delete app support files
rm -rf ~/Library/Application\ Support/$APP_NAME/
rm -rf ~/Library/Caches/$APP_NAME/
rm -rf ~/Library/Caches/$BUNDLE_ID/
rm ~/Library/Preferences/$BUNDLE_ID.plist
rm -rf ~/Library/Saved\ Application\ State/$BUNDLE_ID.savedState/

# Delete container (if sandboxed)
rm -rf ~/Library/Containers/$BUNDLE_ID/

# Delete logs
rm -rf ~/Library/Logs/$APP_NAME/

echo "✅ $APP_NAME deleted completely"
