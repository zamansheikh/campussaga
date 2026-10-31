import { site } from "@/lib/site";

/**
 * Android App Links: lets the app open https://varsitykotha.com/join/…
 * links itself. Lists the SHA-256 of each certificate the app is signed
 * with: the upload key (builds installed by hand) and Google Play's app
 * signing key (installs from Play: Play Console → Test and release → App
 * integrity → App signing key certificate). Fingerprints are public.
 */
const fingerprints = [
  // Upload key (~/varsitykotha-secrets/upload-keystore.jks).
  "0E:4A:03:81:BE:E3:9B:50:52:2F:C5:14:06:A5:60:5A:16:51:0F:D1:0F:D7:DA:6F:FC:FC:89:FA:A9:14:A8:41",
  // Google Play app signing key (from Play Console's Digital Asset Links JSON).
  "C6:71:2B:97:13:0C:08:23:B9:A9:36:CD:6D:7D:62:00:F7:62:59:25:2F:6E:0F:92:7C:84:E4:1C:EE:72:7E:DE",
  // Play's newer "quantum-ready" signing keys, which Play uses on Android 17
  // and later (App integrity → "Copy all certificate fingerprints").
  "AF:69:02:E7:68:1F:D3:94:DA:D2:E8:B5:24:1C:5E:61:11:59:15:52:F8:36:C6:85:F3:3A:0B:30:1B:29:ED:0D",
  "5D:35:0D:CB:7C:09:D0:03:81:5A:A5:F0:A7:27:14:91:43:5B:50:5E:24:48:EC:09:81:D6:B9:BB:36:56:BB:D7",
];

export function GET() {
  return Response.json(
    [
      {
        relation: ["delegate_permission/common.handle_all_urls"],
        target: { namespace: "android_app", package_name: site.androidPackage, sha256_cert_fingerprints: fingerprints },
      },
    ],
    { headers: { "Cache-Control": "public, max-age=3600" } },
  );
}
