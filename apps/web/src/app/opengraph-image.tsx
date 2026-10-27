import { ImageResponse } from "next/og";

export const alt = "Campus Saga — your class routine and campus voice";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

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
        <div style={{ fontSize: 40, opacity: 0.85 }}>Campus Saga</div>
        <div style={{ fontSize: 72, fontWeight: 700, lineHeight: 1.1, marginTop: 24, maxWidth: 1000 }}>
          Your class routine every morning. Your campus voice when it matters.
        </div>
        <div style={{ fontSize: 30, marginTop: 36, opacity: 0.85 }}>For university students in Bangladesh</div>
      </div>
    ),
    size,
  );
}
