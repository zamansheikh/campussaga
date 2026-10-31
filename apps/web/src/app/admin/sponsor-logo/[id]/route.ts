import { revalidatePath } from "next/cache";
import type { NextRequest } from "next/server";

import { forwardImage } from "@/lib/admin/image-routes";

/** Uploads a sponsor's logo (multipart "image", up to 4 MB) through the API; answers with the new `logoUrl`. */
export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const res = await forwardImage(req, {
    id,
    apiPath: `/admin/sponsors/${id}/logo`,
    urlField: "logoUrl",
    maxBytes: 4 << 20,
    notFound: "SPONSOR_NOT_FOUND",
  });
  if (res.ok) {
    revalidatePath("/admin/sponsors");
    revalidatePath(`/admin/sponsors/${id}`);
    revalidatePath("/admin/ads");
  }
  return res;
}
