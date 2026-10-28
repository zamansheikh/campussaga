import { ImageResponse } from "next/og";

import { brandIconSvg } from "@/lib/brand";

export const alt = "VarsityKotha — your class routine and campus voice";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const icon = `data:image/svg+xml;base64,${Buffer.from(brandIconSvg).toString("base64")}`;

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: 80,
          background: "linear-gradient(135deg, #042f2e 0%, #0f766e 100%)",
          color: "white",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
          <img src={icon} width={88} height={88} alt="" />
          <div style={{ fontSize: 44, fontWeight: 700 }}>VarsityKotha</div>
        </div>
        <div style={{ fontSize: 68, fontWeight: 700, lineHeight: 1.1, marginTop: 40, maxWidth: 1000 }}>
          Your class routine every morning. Your campus voice when it matters.
        </div>
        <div style={{ fontSize: 30, marginTop: 36, opacity: 0.85 }}>For university students in Bangladesh</div>
      </div>
    ),
    size,
  );
}
