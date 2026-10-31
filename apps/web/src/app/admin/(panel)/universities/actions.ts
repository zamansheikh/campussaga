"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, ApiError, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { AdminUniversity, Ambassador } from "@/lib/admin/types";

const domain = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^(?=.{3,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$/, "isn't a valid domain");

const optional = z.string().trim().max(120);

const fields = z.object({
  name: z.string().trim().min(2, "Name is too short").max(120),
  nameBn: optional,
  city: z.string().trim().max(60),
  kind: z.enum(["public", "private", ""]),
  website: z
    .string()
    .trim()
    .toLowerCase()
    .refine((v) => v === "" || /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(v), "Website must look like diu.edu.bd (no https://)"),
});

export type UniversityInput = z.input<typeof fields>;

const createSchema = fields.extend({
  slug: z
    .string()
    .trim()
    .toLowerCase()
    .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "Slug: lowercase letters, numbers and dashes"),
  domains: z.array(domain).max(50),
});

function issues(e: z.ZodError) {
  return e.issues.map((i) => i.message).join(" · ");
}

function revalidate() {
  revalidatePath("/admin/universities");
  revalidatePath("/admin", "layout");
}

export async function createUniversity(
  input: UniversityInput & { slug: string; domains: string[] },
): Promise<ActionResult<AdminUniversity>> {
  const parsed = createSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: issues(parsed.error) };
  const { nameBn, city, kind, website, ...rest } = parsed.data;
  try {
    const uni = await api<AdminUniversity>("/admin/universities", {
      method: "POST",
      body: {
        ...rest,
        ...(nameBn ? { nameBn } : {}),
        ...(city ? { city } : {}),
        ...(kind ? { kind } : {}),
        ...(website ? { website } : {}),
      },
    });
    revalidate();
    return { ok: true, data: uni };
  } catch (e) {
    return failure(e);
  }
}

/** Saves only the fields that changed (empty strings clear optional ones). */
export async function updateUniversity(
  id: string,
  patch: Partial<UniversityInput & { active: boolean }>,
): Promise<ActionResult<AdminUniversity>> {
  const parsedId = z.uuid().safeParse(id);
  const parsed = fields.extend({ active: z.boolean() }).partial().safeParse(patch);
  if (!parsedId.success) return { ok: false, error: "That university isn't valid." };
  if (!parsed.success) return { ok: false, error: issues(parsed.error) };
  if (Object.keys(parsed.data).length === 0) return { ok: false, error: "Nothing changed." };
  try {
    const uni = await api<AdminUniversity>(`/admin/universities/${parsedId.data}`, {
      method: "PATCH",
      body: parsed.data,
    });
    revalidate();
    return { ok: true, data: uni };
  } catch (e) {
    return failure(e);
  }
}

export async function setActive(id: string, active: boolean): Promise<ActionResult> {
  const parsedId = z.uuid().safeParse(id);
  if (!parsedId.success) return { ok: false, error: "That university isn't valid." };
  try {
    await api(`/admin/universities/${parsedId.data}`, { method: "PATCH", body: { active } });
    revalidate();
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

export async function setDomains(id: string, domains: string[]): Promise<ActionResult<AdminUniversity>> {
  const parsedId = z.uuid().safeParse(id);
  const parsed = z.array(domain).max(50).safeParse(domains);
  if (!parsedId.success) return { ok: false, error: "That university isn't valid." };
  if (!parsed.success) return { ok: false, error: issues(parsed.error) };
  try {
    const uni = await api<AdminUniversity>(`/admin/universities/${parsedId.data}/domains`, {
      method: "PUT",
      body: { domains: [...new Set(parsed.data)] },
    });
    revalidate();
    return { ok: true, data: uni };
  } catch (e) {
    return failure(e);
  }
}

/**
 * The university's Campus ambassador (§9.3) from `GET /admin/universities/{id}`;
 * null when there is none or the server doesn't have that endpoint.
 */
export async function getAmbassador(universityId: string): Promise<ActionResult<Ambassador | null>> {
  const parsedId = z.uuid().safeParse(universityId);
  if (!parsedId.success) return { ok: false, error: "That university isn't valid." };
  try {
    const uni = await api<AdminUniversity>(`/admin/universities/${parsedId.data}`);
    return { ok: true, data: uni?.ambassador ?? null };
  } catch (e) {
    if (e instanceof ApiError && (e.status === 404 || e.status === 405)) return { ok: true, data: null };
    return failure(e);
  }
}
