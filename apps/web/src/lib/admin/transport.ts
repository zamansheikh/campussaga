/** Bus routes as the API sends them (`/admin/transport/*`, `/transport/*`). */

export type BusDirection = "to_campus" | "from_campus";

export type BusStop = {
  id: string;
  name: string;
  landmark: string;
  /** Minutes after the first stop, going to campus (null: not stopping that way). */
  toCampusMin: number | null;
  /** Minutes after leaving campus, on the way back (null: not stopping that way). */
  fromCampusMin: number | null;
  /** Where the stop is, for the map (null: not placed yet). */
  location: LatLng | null;
};

export type LatLng = { lat: number; lng: number };

export type BusTrip = {
  id: string;
  direction: BusDirection;
  /** "HH:MM", 24-hour. */
  departs: string;
  /** ISO weekdays: 1 = Monday … 7 = Sunday. */
  weekdays: number[];
  note: string;
};

export type BusRoute = {
  id: string;
  universityId: string;
  name: string;
  color: string;
  notes: string;
  active: boolean;
  driverName: string;
  driverPhone: string;
  stops: BusStop[];
  trips: BusTrip[];
  updatedAt: string;
};

export type TransportRep = {
  userId: string;
  email: string;
  name: string | null;
  universityId: string;
  university: string;
  universitySlug: string;
  createdAt: string;
};

export const defaultRouteColor = "#0F766E";

/** The colours the app offers for a route. */
export const routeColors: readonly string[] = ["#0F766E", "#2563EB", "#7C3AED", "#DB2777", "#DC2626", "#EA580C", "#CA8A04", "#16A34A"];

/** Saturday-first week (Bangladesh), as ISO weekdays with short names. */
export const weekDays: { day: number; short: string }[] = [
  { day: 6, short: "Sat" },
  { day: 7, short: "Sun" },
  { day: 1, short: "Mon" },
  { day: 2, short: "Tue" },
  { day: 3, short: "Wed" },
  { day: 4, short: "Thu" },
  { day: 5, short: "Fri" },
];

/** "07:30" → "7:30 AM". */
export function clock12(hhmm: string): string {
  const [h = 0, m = 0] = hhmm.split(":").map(Number);
  return `${h % 12 === 0 ? 12 : h % 12}:${String(m).padStart(2, "0")} ${h < 12 ? "AM" : "PM"}`;
}

/*
 * Stop times for editing, as in the app (packages/campus_core,
 * transport_edit.dart): the API stores minutes from the start of a trip;
 * editors show minutes from the timed stop before ("legs").
 */

/** Minutes from the last timed stop before each stop; the first is the start (0). */
export function legsFromOffsets(offsets: (number | null)[]): (number | null)[] {
  let last: number | null = null;
  return offsets.map((o, i) => {
    if (i === 0) {
      last = o ?? 0;
      return 0;
    }
    if (o == null) return null;
    const leg = Math.max(0, o - (last ?? 0));
    last = o;
    return leg;
  });
}

/** Running totals of [legs]: the first stop at 0, untimed stops null. */
export function offsetsFromLegs(legs: (number | null)[]): (number | null)[] {
  let total = 0;
  return legs.map((l, i) => {
    if (i === 0) return 0;
    if (l == null) return null;
    total += l;
    return total;
  });
}

/** The way back as the reverse of the way there (campus, the last stop, at 0). */
export function mirroredFromCampus(to: (number | null)[]): (number | null)[] {
  const end = to.at(-1) ?? null;
  return to.map((t, i) => (i === to.length - 1 ? 0 : end == null || t == null ? null : end - t));
}

/** Whether the way back is the exact reverse of the way there (or not set). */
export function isMirrored(stops: Pick<BusStop, "toCampusMin" | "fromCampusMin">[]): boolean {
  const back = stops.map((s) => s.fromCampusMin);
  if (back.every((b) => b == null)) return true;
  const mirror = mirroredFromCampus(stops.map((s) => s.toCampusMin));
  return back.every((b, i) => b === mirror[i]);
}

export type StopDraft = { name: string; landmark: string };

/**
 * Stops from pasted text such as a transport notice: one per line, or split
 * by commas, semicolons, "।" or dashes ("Gabtoli --- Campus"). "Name
 * (landmark)" keeps the bracketed part as the landmark; numbering is dropped.
 */
export function parseStopList(text: string): StopDraft[] {
  const parts: string[] = [];
  let buf = "";
  let depth = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i]!;
    if (c === "(") depth++;
    if (c === ")" && depth > 0) depth--;
    const dashRun = c === "-" && text[i + 1] === "-";
    if (c === "\n" || (depth === 0 && ",;،।".includes(c)) || c === "–" || c === "—" || dashRun) {
      parts.push(buf);
      buf = "";
      while (text[i + 1] === "-") i++;
      if (c === "\n") depth = 0;
      continue;
    }
    buf += c;
  }
  parts.push(buf);
  const out: StopDraft[] = [];
  for (let p of parts) {
    p = p
      .replace(/\s+/g, " ")
      .trim()
      .replace(/^\s*(?:[0-9০-৯]{1,3}\s*[.)।:-]\s+|[-•*·]\s*)/u, "")
      .replace(/[.|।]+$/u, "")
      .trim();
    if (!p) continue;
    let name = p;
    let landmark = "";
    const open = p.indexOf("(");
    if (open > 0 && p.endsWith(")")) {
      name = p.slice(0, open).trim();
      landmark = p.slice(open + 1, -1).trim();
    }
    if (name) out.push({ name: name.slice(0, 60), landmark: landmark.slice(0, 100) });
  }
  return out;
}

/**
 * A point typed or pasted as "23.8103, 90.4125", or copied from a Google
 * Maps or OpenStreetMap link. Null when it isn't one.
 */
export function parseLatLng(text: string): LatLng | null {
  const t = text.trim();
  const m =
    t.match(/@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)/) ?? // Google Maps ".../@23.81,90.41,17z"
    t.match(/mlat=(-?\d+(?:\.\d+)?)&mlon=(-?\d+(?:\.\d+)?)/) ?? // OpenStreetMap
    t.match(/^(-?\d+(?:\.\d+)?)\s*[,\s]\s*(-?\d+(?:\.\d+)?)$/);
  if (!m) return null;
  const lat = Number(m[1]);
  const lng = Number(m[2]);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return { lat, lng };
}

export const formatLatLng = (p: LatLng | null) => (p ? `${p.lat.toFixed(6)}, ${p.lng.toFixed(6)}` : "");

export const osmLink = (p: LatLng) => `https://www.openstreetmap.org/?mlat=${p.lat}&mlon=${p.lng}#map=17/${p.lat}/${p.lng}`;


/** A bus being shared live (docs/BUS_LIVE.md 3.4; the admin view has no `mine` and no user ids). */
export type BusRun = {
  direction: BusDirection;
  /** "HH:MM", or null when the run isn't on the timetable. */
  departs: string | null;
  riders: number;
  delayMin: number | null;
  nextStopId: string | null;
  updatedAt: string;
};

export type TripInsight = {
  direction: BusDirection;
  departs: string;
  votes: number;
  onTime: number;
  late: number;
  noShow: number;
  crowded: number;
  /** Median delay at stops over measured runs (null: fewer than 3 runs). */
  delayMin: number | null;
  runs: number;
};

export type RouteActivity = {
  live: { runs: BusRun[] };
  insights: { trips: TripInsight[] };
  sharesLast7Days: number;
  ratingsLast30Days: number;
};
