import { revalidatePath } from "next/cache";
import type { NextRequest } from "next/server";

import { forwardImage } from "@/lib/admin/image-routes";

/** Uploads an ad's image (multipart "image", up to 8 MB) through the API; answers with the new `imageUrl`. */
export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const res = await forwardImage(req, {
    id,
    apiPath: `/admin/promos/${id}/image`,
    urlField: "imageUrl",
    maxBytes: 8 << 20,
    notFound: "PROMO_NOT_FOUND",
  });
  if (res.ok) {
    revalidatePath("/admin/ads");
    revalidatePath(`/admin/ads/${id}`);
  }
  return res;
}
