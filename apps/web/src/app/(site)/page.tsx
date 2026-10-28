import type { StaticImageData } from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  BellRing,
  Bus,
  Calculator,
  CalendarClock,
  Check,
  EyeOff,
  Languages,
  Megaphone,
  Search,
  ShieldCheck,
  Trash2,
} from "lucide-react";

import busShot from "@/assets/screens/08-bus.webp";
import cgpaShot from "@/assets/screens/08-cgpa.webp";
import findShot from "@/assets/screens/07-find.webp";
import groupShot from "@/assets/screens/04-group.webp";
import replyShot from "@/assets/screens/06-issue-reply.webp";
import routineShot from "@/assets/screens/02-routine.webp";
import testsShot from "@/assets/screens/03-today-tests.webp";
import todayShot from "@/assets/screens/01-today.webp";
import todayDarkShot from "@/assets/screens/09-today-dark.webp";
import voiceShot from "@/assets/screens/05-voice.webp";
import { BrandMark } from "@/components/site/brand-mark";
import { PhoneFrame } from "@/components/site/phone-frame";
import { site } from "@/lib/site";
import { cn } from "@/lib/utils";

export default function HomePage() {
  return (
    <>
      <Hero />
      <TrustStrip />
      <div id="features" className="scroll-mt-16">
        <FeatureRow
          chip="Today"
          icon={CalendarClock}
          title="Your day, at a glance"
          body="Open the app in the morning and see your next class, the room and the teacher, with a live countdown."
          points={["Class changes marked right on the card", "Announcements from your CR", "A reminder before every class", "Light and dark themes"]}
          shots={[{ src: todayDarkShot, alt: "The Today screen in dark theme: next class CSE312 in 55 minutes, moved to Lab 5", dark: true }]}
        />
        <FeatureRow
          reverse
          chip="Routine & class changes"
          icon={BellRing}
          title="One routine for your whole section"
          body="Your CR keeps one shared routine. When a class is cancelled, rescheduled or moved, everyone gets a notification at once."
          points={["The whole week, always up to date", "Cancel or move a class in one tap (CR)", "No more screenshots in group chats"]}
          shots={[
            { src: routineShot, alt: "The weekly routine for a section" },
            { src: groupShot, alt: "A class group with a cancelled and a moved class" },
          ]}
        />
        <FeatureRow
          chip="Tests & deadlines"
          icon={Check}
          title="Never miss a quiz or a deadline"
          body="Class tests, assignments and exams sit next to your routine, with a reminder the evening before."
          points={["Quizzes, assignments and exams in one list", "Room, time and syllabus with every test", "Shared with your whole section"]}
          shots={[{ src: testsShot, alt: "Upcoming quiz and assignment on the Today screen" }]}
        />
      </div>
      <CampusVoice />
      <MoreTools />
      <Privacy />
      <FinalCta />
    </>
  );
}

/* ---------- Hero ---------- */

function Hero() {
  return (
    <section className="relative overflow-hidden bg-[linear-gradient(160deg,#14b8a6_0%,#0f9488_38%,#0b5e57_100%)] text-white">
      <Rings />
      <div className="relative mx-auto grid max-w-6xl items-center gap-10 px-4 pt-14 sm:pt-20 lg:grid-cols-[1.05fr_1fr] lg:gap-6 lg:pt-16">
        <div className="pb-2 lg:pb-20">
          <span className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-sm font-medium backdrop-blur">
            <span className="size-2 rounded-full bg-teal-200 shadow-[0_0_0_4px_rgba(153,246,228,0.25)]" />
            {site.playStore.live ? "Now on Google Play" : "Coming soon to Google Play"}
          </span>
          <h1 className="mt-6 text-4xl leading-[1.08] font-extrabold tracking-tight text-balance sm:text-6xl">
            Your class routine and campus voice
          </h1>
          <p lang="bn" className="mt-4 text-xl font-semibold text-teal-50/90 sm:text-2xl">
            তোমার ক্লাস রুটিন আর ক্যাম্পাসের কণ্ঠ
          </p>
          <p className="mt-6 max-w-xl text-lg leading-8 text-teal-50/85">
            {site.name} keeps your section&apos;s routine, class changes and deadlines in one place, and gives you a
            safe, anonymous way to get campus problems fixed. Made for university students in Bangladesh.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <PlayButton />
            <a
              href="#features"
              className="inline-flex h-12 items-center gap-2 rounded-xl px-4 font-semibold text-white/90 transition hover:bg-white/10 hover:text-white"
            >
              See how it works
              <ArrowRight className="size-4" aria-hidden />
            </a>
          </div>
          <ul className="mt-8 flex flex-wrap gap-x-6 gap-y-2 text-sm text-teal-50/85">
            {["Free", "No ads", "English & বাংলা"].map((t) => (
              <li key={t} className="flex items-center gap-1.5">
                <Check className="size-4 text-teal-200" aria-hidden />
                {t}
              </li>
            ))}
          </ul>
        </div>

        <div className="relative mx-auto h-[23rem] w-full max-w-[21rem] sm:h-[33rem] sm:max-w-[28rem] lg:h-[38rem]">
          <PhoneFrame
            src={voiceShot}
            alt="Campus Voice: anonymous campus issues ranked by Me too votes"
            className="absolute top-12 left-2 w-[10rem] -rotate-6 opacity-95 sm:top-16 sm:left-0 sm:w-[15rem]"
          />
          <PhoneFrame
            src={todayShot}
            alt="The Today screen with the next class and announcements"
            eager
            className="absolute top-0 right-2 w-[12rem] rotate-3 sm:right-0 sm:w-[17rem]"
          />
        </div>
      </div>
    </section>
  );
}

function Rings() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0">
      <div className="absolute -top-24 -right-24 size-[36rem] rounded-full border border-white/10" />
      <div className="absolute top-20 right-24 size-[24rem] rounded-full border border-white/[0.07]" />
      <div className="absolute -bottom-40 -left-32 size-[30rem] rounded-full bg-teal-300/20 blur-3xl" />
    </div>
  );
}

function PlayButton({ tone = "light" }: { tone?: "light" | "dark" }) {
  const live = site.playStore.live;
  const inner = (
    <>
      <PlayIcon className="size-6" />
      <span className="flex flex-col text-left leading-tight">
        <span className="text-[0.7rem] font-medium tracking-wide uppercase opacity-70">
          {live ? "Get it on" : "Coming soon to"}
        </span>
        <span className="text-base font-bold">Google Play</span>
      </span>
    </>
  );
  const cls = cn(
    "inline-flex h-12 items-center gap-3 rounded-xl px-5 shadow-lg transition",
    tone === "light" ? "bg-white text-slate-900" : "bg-slate-950 text-white",
    live ? "hover:-translate-y-0.5 hover:shadow-xl" : "cursor-default",
  );
  return live ? (
    <a href={site.playStore.url} className={cls}>
      {inner}
    </a>
  ) : (
    <span className={cls} aria-label="Coming soon to Google Play">
      {inner}
    </span>
  );
}

/** A plain play triangle in the brand teal (not Google's logo). */
function PlayIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className={className}>
      <path d="M6 3.8v16.4c0 .9 1 1.5 1.8 1l13.4-8.2c.7-.5.7-1.5 0-2L7.8 2.8C7 2.3 6 2.9 6 3.8Z" fill="#0f9488" />
    </svg>
  );
}

/* ---------- Trust strip ---------- */

function TrustStrip() {
  const items = [
    { icon: ShieldCheck, text: "Join as a verified student with your university email, or with Google" },
    { icon: Languages, text: "The whole app in English and Bangla, in light or dark" },
    { icon: EyeOff, text: "No ads, no selling data, no tracking analytics" },
  ];
  return (
    <section aria-label="Highlights" className="border-b bg-card">
      <ul className="mx-auto grid max-w-6xl gap-6 px-4 py-8 sm:grid-cols-3">
        {items.map((i) => (
          <li key={i.text} className="flex items-start gap-3">
            <span className="inline-flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary-soft text-primary-soft-foreground">
              <i.icon className="size-5" aria-hidden />
            </span>
            <p className="pt-0.5 text-sm leading-6 text-muted-foreground">{i.text}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

/* ---------- Feature rows ---------- */

type Shot = { src: StaticImageData; alt: string; dark?: boolean };

function Chip({ icon: Icon, children }: { icon: React.ElementType; children: React.ReactNode }) {
  return (
    <span className="inline-flex items-center gap-2 rounded-full bg-primary-soft px-3 py-1 text-sm font-semibold text-primary-soft-foreground">
      <Icon className="size-4" aria-hidden />
      {children}
    </span>
  );
}

function FeatureRow({
  chip,
  icon,
  title,
  body,
  points,
  shots,
  reverse = false,
}: {
  chip: string;
  icon: React.ElementType;
  title: string;
  body: string;
  points: string[];
  shots: [Shot] | [Shot, Shot];
  reverse?: boolean;
}) {
  return (
    <section className="mx-auto grid max-w-6xl items-center gap-10 px-4 py-16 sm:py-20 lg:grid-cols-2 lg:gap-16">
      <div className={cn(reverse && "lg:order-2")}>
        <Chip icon={icon}>{chip}</Chip>
        <h2 className="mt-4 text-3xl font-bold tracking-tight text-balance sm:text-4xl">{title}</h2>
        <p className="mt-4 text-lg leading-8 text-muted-foreground">{body}</p>
        <ul className="mt-6 space-y-3">
          {points.map((p) => (
            <li key={p} className="flex items-start gap-3">
              <span className="mt-0.5 inline-flex size-5 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground">
                <Check className="size-3.5" aria-hidden />
              </span>
              <span className="leading-7">{p}</span>
            </li>
          ))}
        </ul>
      </div>
      <Stage className={cn(reverse && "lg:order-1")}>
        {shots.length === 1 ? (
          <PhoneFrame src={shots[0].src} alt={shots[0].alt} dark={shots[0].dark} crop className="w-[16rem] sm:w-[17rem]" />
        ) : (
          <div className="flex items-start justify-center gap-4 sm:gap-6">
            <PhoneFrame src={shots[0].src} alt={shots[0].alt} crop className="w-[10rem] sm:w-[15rem]" />
            <PhoneFrame src={shots[1].src} alt={shots[1].alt} crop className="mt-10 w-[10rem] sm:w-[15rem]" />
          </div>
        )}
      </Stage>
    </section>
  );
}

/** The soft teal backdrop behind screenshots. */
function Stage({ className, children }: { className?: string; children: React.ReactNode }) {
  return (
    <div
      className={cn(
        "relative flex justify-center overflow-hidden rounded-[2rem] bg-[radial-gradient(120%_90%_at_50%_0%,var(--primary-soft),transparent_70%)] px-4 pt-10",
        className,
      )}
    >
      {children}
    </div>
  );
}

/* ---------- Campus Voice ---------- */

function CampusVoice() {
  const steps = [
    { title: "Raise it anonymously", body: "Post a campus problem without your name. Add a photo if it helps." },
    { title: "Others add “Me too”", body: "The more students share a problem, the higher it rises." },
    { title: "Hear back officially", body: "University officials reply in the open. Follow every step until it’s solved." },
  ];
  return (
    <section className="relative overflow-hidden bg-[#0b2f2c] text-white">
      <div aria-hidden className="pointer-events-none absolute inset-0">
        <div className="absolute -top-40 left-1/2 h-96 w-[48rem] -translate-x-1/2 rounded-full bg-teal-500/25 blur-3xl" />
      </div>
      <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 py-20 sm:py-24 lg:grid-cols-[1fr_1.1fr]">
        <div>
          <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1 text-sm font-semibold text-teal-100">
            <Megaphone className="size-4" aria-hidden />
            Campus Voice
          </span>
          <h2 className="mt-4 text-3xl font-bold tracking-tight text-balance sm:text-4xl">
            Raise campus problems, safely. Get real answers.
          </h2>
          <p lang="bn" className="mt-3 text-lg text-teal-100/80">
            ক্যাম্পাসের সমস্যা তুলে ধরো, নাম না জানিয়েই।
          </p>
          <ol className="mt-8 space-y-6">
            {steps.map((s, i) => (
              <li key={s.title} className="flex gap-4">
                <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-full bg-teal-400/20 font-bold text-teal-100 ring-1 ring-teal-300/30">
                  {i + 1}
                </span>
                <div>
                  <h3 className="font-semibold">{s.title}</h3>
                  <p className="mt-1 leading-7 text-teal-50/75">{s.body}</p>
                </div>
              </li>
            ))}
          </ol>
          <p className="mt-8 text-sm leading-6 text-teal-50/60">
            Posts are checked by moderators and an on-server photo filter. Anyone can report a post.
          </p>
        </div>
        <div className="flex items-start justify-center gap-4 sm:gap-6">
          <PhoneFrame src={voiceShot} alt="Campus Voice issues list" crop className="w-[10.5rem] sm:w-[16rem]" />
          <PhoneFrame
            src={replyShot}
            alt="An issue with an official reply from the university"
            crop
            className="mt-12 w-[10.5rem] sm:w-[16rem]"
          />
        </div>
      </div>
    </section>
  );
}

/* ---------- More tools ---------- */

function MoreTools() {
  const tools = [
    {
      icon: Search,
      title: "Find your class",
      body: "Search your university’s routines and join your section in seconds, or add only the courses you take.",
      shot: { src: findShot, alt: "Searching for a section's routine" },
    },
    {
      icon: Bus,
      title: "Bus routes",
      body: "The next bus from your stop, with your university’s routes and times.",
      shot: { src: busShot, alt: "University bus routes with the next departure" },
    },
    {
      icon: Calculator,
      title: "CGPA planner",
      body: "Work out your CGPA on the UGC scale. Your grades stay on your phone.",
      shot: { src: cgpaShot, alt: "The CGPA calculator" },
    },
  ];
  return (
    <section className="mx-auto max-w-6xl px-4 py-20 sm:py-24">
      <div className="mx-auto max-w-2xl text-center">
        <h2 className="text-3xl font-bold tracking-tight text-balance sm:text-4xl">Everything else campus needs</h2>
        <p className="mt-4 text-lg text-muted-foreground">Small tools that save you a question in the group chat.</p>
      </div>
      <div className="mt-12 grid gap-6 md:grid-cols-3">
        {tools.map((t) => (
          <article key={t.title} className="flex flex-col overflow-hidden rounded-3xl border bg-card shadow-xs">
            <div className="p-6 pb-0">
              <span className="inline-flex size-10 items-center justify-center rounded-xl bg-primary-soft text-primary-soft-foreground">
                <t.icon className="size-5" aria-hidden />
              </span>
              <h3 className="mt-4 text-lg font-semibold">{t.title}</h3>
              <p className="mt-2 leading-7 text-muted-foreground">{t.body}</p>
            </div>
            <div className="mt-6 flex flex-1 items-start justify-center bg-[radial-gradient(100%_80%_at_50%_100%,var(--primary-soft),transparent_75%)] px-6 pt-2">
              <PhoneFrame
                src={t.shot.src}
                alt={t.shot.alt}
                className="w-[12.5rem] [mask-image:linear-gradient(to_bottom,black_75%,transparent)] max-h-[18rem] overflow-hidden"
              />
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

/* ---------- Privacy ---------- */

function Privacy() {
  const items = [
    {
      icon: EyeOff,
      title: "Anonymous where it matters",
      body: "Campus Voice posts never show your name unless you choose to. Even officials can’t see who posted.",
    },
    {
      icon: ShieldCheck,
      title: "No ads, no selling data",
      body: "No advertising, no tracking analytics. Crash reports are not linked to your account.",
    },
    {
      icon: Trash2,
      title: "Delete any time",
      body: "Delete your account from the Profile tab at any time, or delete only some of your data.",
      link: { href: "/delete-account", label: "How deletion works" },
    },
  ];
  return (
    <section className="border-y bg-card">
      <div className="mx-auto max-w-6xl px-4 py-20">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Private by design</h2>
            <p className="mt-3 text-lg text-muted-foreground">Built for students, not for advertisers.</p>
          </div>
          <Link
            href="/privacy"
            className="inline-flex items-center gap-1.5 font-semibold text-primary underline-offset-4 hover:underline"
          >
            Read the privacy policy
            <ArrowRight className="size-4" aria-hidden />
          </Link>
        </div>
        <div className="mt-10 grid gap-6 sm:grid-cols-3">
          {items.map((i) => (
            <div key={i.title} className="rounded-2xl border bg-background p-6">
              <i.icon className="size-6 text-primary" aria-hidden />
              <h3 className="mt-4 text-lg font-semibold">{i.title}</h3>
              <p className="mt-2 leading-7 text-muted-foreground">{i.body}</p>
              {i.link ? (
                <Link
                  href={i.link.href}
                  className="mt-3 inline-block text-sm font-semibold text-primary underline-offset-4 hover:underline"
                >
                  {i.link.label}
                </Link>
              ) : null}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- Final call to action ---------- */

function FinalCta() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-20">
      <div className="relative overflow-hidden rounded-[2rem] bg-[linear-gradient(135deg,#14b8a6_0%,#0f9488_45%,#0b5e57_100%)] px-6 py-14 text-center text-white sm:px-12">
        <div aria-hidden className="pointer-events-none absolute -top-20 -right-20 size-80 rounded-full border border-white/10" />
        <div aria-hidden className="pointer-events-none absolute -bottom-24 -left-16 size-72 rounded-full border border-white/10" />
        <BrandMark className="relative mx-auto size-16 rounded-[22%] shadow-xl ring-1 ring-white/20" />
        <h2 className="relative mt-6 text-3xl font-extrabold tracking-tight sm:text-4xl">{site.name}</h2>
        <p lang="bn" className="relative mt-1 text-xl font-semibold text-teal-50/90">
          ভার্সিটি কথা
        </p>
        <p className="relative mx-auto mt-4 max-w-xl text-lg text-teal-50/85">
          Free for every student at a UGC-approved university in Bangladesh.
        </p>
        <div className="relative mt-8 flex justify-center">
          <PlayButton />
        </div>
        <p className="relative mt-8 text-sm text-teal-50/75">
          A CR, a club or university staff and want your routine or buses on {site.name}?{" "}
          <a href={`mailto:${site.supportEmail}`} className="font-semibold text-white underline underline-offset-4">
            {site.supportEmail}
          </a>
        </p>
      </div>
    </section>
  );
}
