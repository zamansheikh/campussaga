"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { BusRoute, TransportRep } from "@/lib/admin/transport";

const routeSchema = z.object({
  name: z.string().trim().min(1, "Give the route a name.").max(60, "Keep the name under 60 characters."),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Pick a colour."),
  notes: z.string().trim().max(500, "Keep the notes under 500 characters."),
  active: z.boolean(),
  driverName: z.string().trim().max(60, "Keep the driver's name under 60 characters."),
  // Bangla digits, spaces and dashes are fine; the API stores digits only.
  driverPhone: z
    .string()
    .trim()
    .max(30)
    .refine((v) => v === "" || /^\+?[0-9০-৯][0-9০-৯ ().-]{4,24}$/.test(v), "Use a phone number like 01712345678."),
});

export type RouteInput = z.input<typeof routeSchema>;

const minutes = z.number().int().min(0).max(600).nullable();

const stopsSchema = z
  .array(
    z.object({
      name: z.string().trim().min(1, "Every stop needs a name.").max(60),
      landmark: z.string().trim().max(100),
      toCampusMin: minutes,
      fromCampusMin: minutes,
      // Always sent: null removes the stop from the map.
      location: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }).nullable(),
    }),
  )
  .max(60, "A route can have at most 60 stops.");

export type StopInput = z.input<typeof stopsSchema>[number];

const tripsSchema = z
  .array(
    z.object({
      direction: z.enum(["to_campus", "from_campus"]),
      departs: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Every departure needs a time."),
      weekdays: z.array(z.number().int().min(1).max(7)).min(1, "Every departure needs at least one day.").max(7),
      note: z.string().trim().max(100),
    }),
  )
  .max(150, "A route can have at most 150 departures.");

export type TripInput = z.input<typeof tripsSchema>[number];

const id = z.uuid();

function invalid(e: z.ZodError): { ok: false; error: string } {
  return { ok: false, error: e.issues[0]?.message ?? "That isn't valid." };
}

function refresh(routeId?: string) {
  revalidatePath("/admin/transport");
  if (routeId) revalidatePath(`/admin/transport/${routeId}`);
}

/** Adds a route to a university (hidden until it is turned on, if so chosen). */
export async function createRoute(universityId: string, input: RouteInput): Promise<ActionResult<BusRoute>> {
  const uni = id.safeParse(universityId);
  if (!uni.success) return { ok: false, error: "Choose a university first." };
  const parsed = routeSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  try {
    const route = await api<BusRoute>("/admin/transport/routes", {
      method: "POST",
      body: { universityId: uni.data, ...parsed.data },
    });
    refresh();
    return { ok: true, data: route };
  } catch (e) {
    return failure(e);
  }
}

export async function updateRoute(routeId: string, input: RouteInput): Promise<ActionResult<BusRoute>> {
  const rid = id.safeParse(routeId);
  if (!rid.success) return { ok: false, error: "That route isn't valid." };
  const parsed = routeSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  try {
    const route = await api<BusRoute>(`/transport/routes/${rid.data}`, { method: "PUT", body: parsed.data });
    refresh(rid.data);
    return { ok: true, data: route };
  } catch (e) {
    return failure(e);
  }
}

export async function deleteRoute(routeId: string): Promise<ActionResult> {
  const rid = id.safeParse(routeId);
  if (!rid.success) return { ok: false, error: "That route isn't valid." };
  try {
    await api(`/transport/routes/${rid.data}`, { method: "DELETE" });
    refresh();
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Replaces a route's stops (in order, from the far end to campus). */
export async function saveStops(routeId: string, stops: StopInput[]): Promise<ActionResult<BusRoute>> {
  const rid = id.safeParse(routeId);
  if (!rid.success) return { ok: false, error: "That route isn't valid." };
  const parsed = stopsSchema.safeParse(stops);
  if (!parsed.success) return invalid(parsed.error);
  try {
    const route = await api<BusRoute>(`/transport/routes/${rid.data}/stops`, {
      method: "PUT",
      body: { stops: parsed.data },
    });
    refresh(rid.data);
    return { ok: true, data: route };
  } catch (e) {
    return failure(e);
  }
}

/** Replaces a route's timetable. */
export async function saveTrips(routeId: string, trips: TripInput[]): Promise<ActionResult<BusRoute>> {
  const rid = id.safeParse(routeId);
  if (!rid.success) return { ok: false, error: "That route isn't valid." };
  const parsed = tripsSchema.safeParse(trips);
  if (!parsed.success) return invalid(parsed.error);
  try {
    const route = await api<BusRoute>(`/transport/routes/${rid.data}/trips`, {
      method: "PUT",
      body: { trips: parsed.data },
    });
    refresh(rid.data);
    return { ok: true, data: route };
  } catch (e) {
    return failure(e);
  }
}

/** Ends every open live-sharing session on a route and says how many ended. */
export async function endLiveSharing(routeId: string): Promise<ActionResult<{ ended: number }>> {
  const rid = id.safeParse(routeId);
  if (!rid.success) return { ok: false, error: "That route isn't valid." };
  try {
    const res = await api<{ ended: number }>(`/admin/transport/routes/${rid.data}/live/end`, { method: "POST", body: {} });
    refresh(rid.data);
    const n = res.ended ?? 0;
    return {
      ok: true,
      data: { ended: n },
      message: n === 0 ? "Nobody was sharing" : `Ended ${n} sharing ${n === 1 ? "session" : "sessions"}`,
    };
  } catch (e) {
    return failure(e);
  }
}

/** Lets a student edit their university's bus routes in the app. */
export async function addRep(userId: string, universityId: string): Promise<ActionResult<TransportRep[]>> {
  const parsed = z.object({ userId: z.uuid("Choose a user."), universityId: z.uuid("Choose a university.") }).safeParse({
    userId,
    universityId,
  });
  if (!parsed.success) return invalid(parsed.error);
  try {
    const res = await api<{ items: TransportRep[] }>("/admin/transport/reps", { method: "PUT", body: parsed.data });
    refresh();
    return { ok: true, data: res.items };
  } catch (e) {
    return failure(e);
  }
}

export async function removeRep(userId: string): Promise<ActionResult> {
  const uid = id.safeParse(userId);
  if (!uid.success) return { ok: false, error: "That user isn't valid." };
  try {
    await api(`/admin/transport/reps/${uid.data}`, { method: "DELETE" });
    refresh();
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}
