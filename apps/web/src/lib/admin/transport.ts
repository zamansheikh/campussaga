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
};

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
