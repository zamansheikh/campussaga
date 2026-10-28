import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Download, ExternalLink, KeyRound } from "lucide-react";

import { BrandMark } from "@/components/site/brand-mark";
import { playUrl, site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Join a class group",
  description: `You're invited to a class group on ${site.name}: your section's routine, class changes and deadlines.`,
  robots: { index: false, follow: false },
};

const codeRe = /^[A-HJ-NP-Z]{6}$/;

/**
 * Where a shared invite link lands when the app isn't installed (or the
 * link opened in a browser): the code, a Google Play button that passes the
 * code on (the app then offers to join after installing), and "Open in the
 * app" for Android. Shows nothing about the group itself.
 */
export default async function JoinPage({ params }: { params: Promise<{ code: string }> }) {
  const { code: raw } = await params;
  const code = raw.toUpperCase();
  if (!codeRe.test(code)) notFound();
  const play = playUrl(code);
  const intent = `intent://varsitykotha.com/join/${code}#Intent;scheme=https;package=${site.androidPackage};S.browser_fallback_url=${encodeURIComponent(play)};end`;

  return (
    <section className="mx-auto max-w-xl px-4 py-12 sm:py-16">
      <div className="overflow-hidden rounded-[2rem] bg-[linear-gradient(160deg,#14b8a6_0%,#0f9488_40%,#0b5e57_100%)] p-8 text-center text-white shadow-xl sm:p-10">
        <BrandMark className="mx-auto size-16 rounded-[22%] shadow-lg ring-1 ring-white/20" />
        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">
          You&apos;re invited to a class group
        </h1>
        <p lang="bn" className="mt-1 text-lg font-semibold text-teal-50/90">
          তোমাকে একটি ক্লাস গ্রুপে আমন্ত্রণ জানানো হয়েছে
        </p>
        <p className="mt-4 text-teal-50/85">
          Your section&apos;s routine, class changes and deadlines, on {site.name}.
        </p>

        <div className="mx-auto mt-8 w-fit rounded-2xl bg-white/12 px-6 py-4 ring-1 ring-white/25">
          <p className="flex items-center justify-center gap-1.5 text-xs font-semibold tracking-wide text-teal-50/80 uppercase">
            <KeyRound className="size-3.5" aria-hidden /> Group code
          </p>
          <p className="mt-1 font-mono text-4xl font-bold tracking-[0.3em]" aria-label={code.split("").join(" ")}>
            {code}
          </p>
        </div>

        <div className="mt-8 grid gap-3 sm:grid-cols-2">
          <a
            href={play}
            className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-white px-5 font-bold text-slate-900 shadow-lg transition hover:-translate-y-0.5"
          >
            <Download className="size-5 text-teal-700" aria-hidden />
            Get it on Google Play
          </a>
          <a
            href={intent}
            className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-white/10 px-5 font-semibold text-white ring-1 ring-white/30 transition hover:bg-white/15"
          >
            <ExternalLink className="size-5" aria-hidden />
            Open in the app
          </a>
        </div>
      </div>

      <ol className="mt-8 space-y-4 text-muted-foreground">
        <li className="flex gap-3">
          <span className="inline-flex size-7 shrink-0 items-center justify-center rounded-full bg-primary-soft text-sm font-bold text-primary-soft-foreground">
            1
          </span>
          <span>
            Install {site.name} from Google Play and sign in with your university email (or Google).
            <span lang="bn" className="block text-sm">
              Google Play থেকে ভার্সিটি কথা ইনস্টল করে বিশ্ববিদ্যালয়ের ইমেইল (বা Google) দিয়ে সাইন ইন করো।
            </span>
          </span>
        </li>
        <li className="flex gap-3">
          <span className="inline-flex size-7 shrink-0 items-center justify-center rounded-full bg-primary-soft text-sm font-bold text-primary-soft-foreground">
            2
          </span>
          <span>
            The app offers to join this group. If it doesn&apos;t, tap <strong>Join with a code</strong> and enter{" "}
            <strong className="font-mono tracking-widest">{code}</strong>.
            <span lang="bn" className="block text-sm">
              অ্যাপ নিজেই গ্রুপে যোগ দিতে বলবে। না বললে <strong>কোড দিয়ে যোগ দাও</strong> চেপে{" "}
              <strong className="font-mono tracking-widest">{code}</strong> লেখো।
            </span>
          </span>
        </li>
      </ol>
    </section>
  );
}
