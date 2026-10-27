import { BellRing, CalendarClock, Megaphone, ShieldCheck } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { site } from "@/lib/site";

const features = [
  {
    icon: CalendarClock,
    title: "My Class",
    body: "Your weekly routine, a reminder before every class, and an alert when a class is cancelled or the room changes.",
  },
  {
    icon: Megaphone,
    title: "Campus Voice",
    body: "Raise campus problems safely, see how many classmates have the same problem, and follow them until they are fixed.",
    soon: true,
  },
  {
    icon: ShieldCheck,
    title: "Private by design",
    body: "No ads, no selling data, no tracking analytics. Delete your account any time from the app.",
  },
];

export default function HomePage() {
  return (
    <>
      <section className="relative overflow-hidden">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 -top-40 -z-10 mx-auto h-96 max-w-3xl rounded-full bg-primary/15 blur-3xl"
        />
        <div className="mx-auto grid max-w-5xl items-center gap-12 px-4 pt-16 pb-12 sm:pt-24 lg:grid-cols-[1.2fr_1fr]">
          <div>
            <Badge variant="soft" className="mb-5 px-3 py-1 text-sm">
              Coming soon to Google Play
            </Badge>
            <h1 className="text-4xl font-bold tracking-tight text-balance sm:text-5xl">
              Your class routine every morning. Your campus voice when it matters.
            </h1>
            <p className="mt-5 text-lg leading-8 text-muted-foreground">
              {site.name} is a student app for universities in Bangladesh. Students join with their university email
              as verified students, or with a Google account if their university gives no email.
            </p>
            <p lang="bn" className="mt-4 leading-8 text-muted-foreground">
              প্রতিদিন সকালে তোমার ক্লাস রুটিন, আর দরকারের সময় ক্যাম্পাসে তোমার কণ্ঠ। বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যাচাই
              করা শিক্ষার্থী হিসেবে যোগ দাও, অথবা বিশ্ববিদ্যালয় ইমেইল না দিলে Google অ্যাকাউন্ট দিয়ে।
            </p>
          </div>
          <TodayPreview />
        </div>
      </section>

      <section aria-labelledby="features" className="mx-auto max-w-5xl px-4 pb-16">
        <h2 id="features" className="sr-only">
          Features
        </h2>
        <div className="grid gap-4 sm:grid-cols-3">
          {features.map((f) => (
            <div key={f.title} className="rounded-2xl border bg-card p-6 shadow-xs">
              <div className="flex items-center justify-between">
                <span className="inline-flex size-10 items-center justify-center rounded-xl bg-primary-soft text-primary-soft-foreground">
                  <f.icon className="size-5" aria-hidden />
                </span>
                {f.soon ? <Badge variant="outline">Coming next</Badge> : null}
              </div>
              <h3 className="mt-4 text-lg font-semibold">{f.title}</h3>
              <p className="mt-2 leading-7 text-muted-foreground">{f.body}</p>
            </div>
          ))}
        </div>
        <p className="mt-8 text-center text-muted-foreground">
          Works with student email from every UGC-approved university in Bangladesh, including Google Workspace
          university accounts.
        </p>
      </section>
    </>
  );
}

/** A decorative glimpse of the app's Today screen. */
function TodayPreview() {
  return (
    <div aria-hidden className="mx-auto w-full max-w-sm rounded-[2rem] border bg-card p-3 shadow-xl">
      <div className="rounded-[1.5rem] bg-background p-5">
        <p className="text-sm text-muted-foreground">Today · Sunday</p>
        <div className="mt-3 rounded-2xl bg-primary p-4 text-primary-foreground">
          <p className="text-xs font-medium tracking-wide uppercase opacity-80">Next class · in 25 min</p>
          <p className="mt-1 text-xl font-semibold">CSE311</p>
          <p className="text-sm opacity-90">Database Systems · Room 402</p>
        </div>
        <ul className="mt-4 space-y-2">
          {[
            ["10:30", "MAT201", "Room 305", false],
            ["12:00", "CSE313", "Moved to Lab 2", true],
          ].map(([time, code, room, changed]) => (
            <li key={String(code)} className="flex items-center gap-3 rounded-xl border bg-card px-3 py-2.5">
              <span className="w-12 text-sm text-muted-foreground tabular-nums">{time}</span>
              <span className="flex-1">
                <span className="block text-sm font-semibold">{code}</span>
                <span className="block text-xs text-muted-foreground">{room}</span>
              </span>
              {changed ? <Badge variant="warning">Changed</Badge> : null}
            </li>
          ))}
        </ul>
        <div className="mt-4 flex items-center gap-2 rounded-xl bg-primary-soft px-3 py-2 text-sm text-primary-soft-foreground">
          <BellRing className="size-4" />
          Reminder 10 min before every class
        </div>
      </div>
    </div>
  );
}
