import type { NextRequest } from "next/server";

import { passImage } from "@/lib/admin/image-routes";

/** An ad's image, at the path the API gives as `imageUrl` (`/promos/{id}/image?v=…`). */
export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return passImage(req, `/promos/${id}/image`, id);
}
