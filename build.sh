#!/bin/bash

set -euo

# name: Download certificate bundle
echo "==> Downloading certificate bundle..."
curl --etag-compare etag.txt --etag-save etag.txt --remote-name https://curl.se/ca/cacert.pem

# name: Split certificate bundle
echo "==> Splitting certificate bundle..."
csplit -z -f cert- cacert.pem '/-----BEGIN CERTIFICATE-----/' '{*}'

# name: Get certificate CAs, Convert to DER binary with .crt format, Name it with CAs instead.
echo "==> Processing and converting certificates..."
for f in cert-*; do
    openssl x509 -in "$f" -noout >/dev/null 2>&1 || continue
    CN=$(openssl x509 -in "$f" -noout -subject -nameopt RFC2253 | sed -n 's/.*CN=\([^,]*\).*/\1/p')
    
    CN_CLEAN=$(echo "$CN" | tr '/ ' '__')
    mv "$f" "${CN_CLEAN}.pem"
done

for f in *.pem; do
    openssl x509 -in "$f" -out "${f%.pem}.crt" -outform DER
done

# name: Compress to .zip and .iso
echo "==> Compressing to .zip..."
zip cacert.zip *.crt

# name: Install mkisofs and compress to .iso too
echo "==> Installing tools and creating .iso..."
sudo apt update && sudo apt install -y mkisofs genisoimage xorriso
xorriso -as mkisofs -iso-level 3 -J -joliet-long -R -allow-lowercase -V "CURL_CAEXTRACT_DER" -o cacert.iso *.crt

echo "==> All processes completed successfully!"