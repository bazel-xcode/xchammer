#!/bin/bash

# The absolute path to the directory where the unprocessed archive will be
# extracted for post-processing and signing.
readonly WORK_DIR=${CODESIGNING_FOLDER_PATH}

# Skip ad hoc code signing for simulator..
if [[ ${PLATFORM_NAME} == "iphonesimulator" ]]; then
    exit 0
fi

# Perform ad hoc code signing based on a provisioning profile and entitlements.
readonly PROFILE="${HAMMER_PROFILE_FILE}"

readonly ENTITLEMENTS="${HAMMER_ENTITLEMENTS_FILE}"

echo "Looking up identity in profile ($PROFILE) with entitlements ($ENTITLEMENTS).."

# Sign the application, if requested. This may expand to nothing in the case
# where signing is not being performed.
VERIFIED_ID=$( security find-identity -v -p codesigning | grep -F "$(PLIST=$(mktemp -t cert.plist) && trap "rm ${PLIST}" EXIT && ( STDERR=$(mktemp -t openssl.stderr) && trap "rm -f ${STDERR}" EXIT && security cms -D -i $PROFILE 2> ${STDERR} || ( >&2 echo 'Could not extract plist from provisioning profile'  && >&2 cat ${STDERR} && exit 1 ) ) > ${PLIST} && /usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' ${PLIST} | openssl x509 -inform DER -noout -fingerprint | cut -d= -f2 | sed -e s#:##g )" | xargs | cut -d' ' -f2 )

echo "Found identity ($VERIFIED_ID)"

if [[ -z "$VERIFIED_ID" ]]; then
  echo error: Could not find a valid identity in the keychain matching "$( PLIST=$(mktemp -t cert.plist) && trap "rm ${PLIST}" EXIT && ( STDERR=$(mktemp -t openssl.stderr) && trap "rm -f ${STDERR}" EXIT && security cms -D -i $PROFILE 2> ${STDERR} || ( >&2 echo 'Could not extract plist from provisioning profile'  && >&2 cat ${STDERR} && exit 1 ) ) > ${PLIST} && /usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' ${PLIST} | openssl x509 -inform DER -noout -fingerprint | cut -d= -f2 | sed -e s#:##g )"
  exit 1
fi

echo "Signing.."

ditto $PROFILE $WORK_DIR/embedded.mobileprovision

ls $WORK_DIR/Frameworks/* >& /dev/null && /usr/bin/codesign --force --sign $VERIFIED_ID --entitlements $ENTITLEMENTS $WORK_DIR/Frameworks/*
ls $WORK_DIR/PlugIns/* >& /dev/null && /usr/bin/codesign --force --sign $VERIFIED_ID --entitlements $ENTITLEMENTS $WORK_DIR/PlugIns/*

/usr/bin/codesign --force --sign $VERIFIED_ID --entitlements $ENTITLEMENTS $WORK_DIR
