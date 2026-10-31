import type { Metadata } from "next";
import { Download, ExternalLink, GraduationCap } from "lucide-react";
import { cache } from "react";

import { BrandMark } from "@/components/site/brand-mark";
import { publicApi } from "@/lib/public-api";
import { inviteUrl, playUrl, site } from "@/lib/site";

const codeRe = /^[a-z0-9]{8}$/;

type Inviter = { name: string; university?: { name: string } | null };

/** The inviter for a code, or null (unknown code, bad format, API down). Once per request. */
const getInviter = cache(async (code: string): Promise<Inviter | null> => {
  if (!codeRe.test(code)) return null;
  const res = await publicApi<Inviter>(`/referral/${code}`);
  return res?.name ? res : null;
});

const pitch = "Your class routine, reminders and a safe, anonymous voice for campus problems, made for Bangladeshi universities.";

export async function generateMetadata({ params }: { params: Promise<{ code: string }> }): Promise<Metadata> {
  const { code } = await params;
  const who = await getInviter(code.toLowerCase());
  const title = who ? `${who.name} invited you to ${site.name}` : `You're invited to ${site.name}`;
  const description = who?.university?.name ? `${pitch} ${who.name} studies at ${who.university.name}.` : pitch;
  return {
    title,
    description,
    robots: { index: false, follow: false },
    openGraph: { type: "website", siteName: site.name, title, description, url: `${site.url}/r/${code.toLowerCase()}` },
    twitter: { card: "summary_large_image", title, description },
  };
}

/**
 * Where a personal invite link lands when the app isn't installed (or the
 * link opened in a browser): who invited you, a Google Play button whose
 * install referrer carries the code, and "Open in the app" for Android.
 * An unknown code or an API error shows a generic invite instead.
 */
export default async function InvitePage({ params }: { params: Promise<{ code: string }> }) {
  const { code: raw } = await params;
  const code = raw.toLowerCase();
  const who = await getInviter(code);
  const play = who ? inviteUrl(code) : playUrl();
  const intent = `intent://varsitykotha.com/r/${code}#Intent;scheme=https;package=${site.androidPackage};S.browser_fallback_url=${encodeURIComponent(play)};end`;

  return (
    <section className="mx-auto max-w-xl px-4 py-12 sm:py-16">
      <div className="overflow-hidden rounded-[2rem] bg-[linear-gradient(160deg,#14b8a6_0%,#0f9488_40%,#0b5e57_100%)] p-8 text-center text-white shadow-xl sm:p-10">
        <BrandMark className="mx-auto size-16 rounded-[22%] shadow-lg ring-1 ring-white/20" />
        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">
          {who ? `${who.name} invited you to ${site.name}` : `You're invited to ${site.name}`}
        </h1>
        <p lang="bn" className="mt-1 text-lg font-semibold text-teal-50/90">
          {who ? `${who.name} তোমাকে ভার্সিটি কথায় আমন্ত্রণ জানিয়েছে` : "তোমাকে ভার্সিটি কথায় আমন্ত্রণ জানানো হয়েছে"}
        </p>
        {who?.university?.name ? (
          <p className="mt-3 flex items-center justify-center gap-2 text-sm font-medium text-teal-50/90">
            <GraduationCap className="size-4 shrink-0" aria-hidden />
            {who.university.name}
          </p>
        ) : null}
        <p className="mt-4 text-teal-50/85">{pitch}</p>
        <p lang="bn" className="mt-1 text-sm text-teal-50/80">
          ক্লাস রুটিন, রিমাইন্ডার আর ক্যাম্পাসের সমস্যা নিরাপদে ও বেনামে জানানোর জায়গা, বাংলাদেশের বিশ্ববিদ্যালয়ের শিক্ষার্থীদের জন্য।
        </p>

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

      <p className="mt-8 text-center text-sm text-muted-foreground">
        Install {site.name}, then sign in with your university email (or Google). It&apos;s free.
        <span lang="bn" className="block">
          ভার্সিটি কথা ইনস্টল করে বিশ্ববিদ্যালয়ের ইমেইল (বা Google) দিয়ে সাইন ইন করো। এটি বিনামূল্যে।
        </span>
      </p>
    </section>
  );
}
