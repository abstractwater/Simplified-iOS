#!/bin/bash

# SUMMARY
#   Exports an archive for SimplyE / Open eBooks and generates the related ipa.
#
# SYNOPSIS
#   xcode-export-adhoc.sh [ simplye | SE | openebooks | OE ]
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-export-adhoc.sh simplye
#
# RESULTS
#   The generated .ipa is placed in its own directory inside
#   `./Build/exports-adhoc`.

source "$(dirname $0)/xcode-settings.sh"

echo "Exporting $ARCHIVE_NAME for Ad-Hoc distribution..."

mkdir -p "$ADHOC_EXPORT_PATH"

xcodebuild -archivePath "$ARCHIVE_PATH.xcarchive" \
            -exportOptionsPlist "$APP_NAME_FOLDER/exportOptions-adhoc.plist" \
            -exportPath "$ADHOC_EXPORT_PATH" \
            -allowProvisioningUpdates \
            -exportArchive #| xcpretty