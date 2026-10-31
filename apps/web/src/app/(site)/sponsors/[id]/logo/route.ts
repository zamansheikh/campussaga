import type { NextRequest } from "next/server";

import { passImage } from "@/lib/admin/image-routes";

/** A sponsor's logo, at the path the API gives as `logoUrl` (`/sponsors/{id}/logo?v=…`). */
export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return passImage(req, `/sponsors/${id}/logo`, id);
}
