import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Download, ExternalLink, MessagesSquare } from "lucide-react";

import { BrandMark } from "@/components/site/brand-mark";
import { playUrl, site } from "@/lib/site";

export const metadata: Metadata = {
  title: "A post on Campus",
  description: `A student shared a post from Campus on ${site.name}: your university's own space to share, ask and get things fixed.`,
  robots: { index: false, follow: false },
};

const idRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Where a shared Campus post link lands when the app isn't installed (or
 * the link opened in a browser). Posts are private to a university, so the
 * page shows nothing of the post: only Open in the app and Google Play.
 */
export default async function SharedPostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!idRe.test(id)) notFound();
  const play = playUrl();
  const intent = `intent://varsitykotha.com/c/${id}#Intent;scheme=https;package=${site.androidPackage};S.browser_fallback_url=${encodeURIComponent(play)};end`;

  return (
    <section className="mx-auto max-w-xl px-4 py-12 sm:py-16">
      <div className="overflow-hidden rounded-[2rem] bg-[linear-gradient(160deg,#14b8a6_0%,#0f9488_40%,#0b5e57_100%)] p-8 text-center text-white shadow-xl sm:p-10">
        <BrandMark className="mx-auto size-16 rounded-[22%] shadow-lg ring-1 ring-white/20" />
        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">
          This post is on {site.name}
        </h1>
        <p lang="bn" className="mt-1 text-lg font-semibold text-teal-50/90">
          পোস্টটি ভার্সিটি কথায় আছে
        </p>
        <p className="mt-4 flex items-center justify-center gap-2 text-teal-50/85">
          <MessagesSquare className="size-5 shrink-0" aria-hidden />
          <span>Campus is your university&apos;s own space: share, ask, run polls and get things fixed.</span>
        </p>
        <p lang="bn" className="mt-1 text-sm text-teal-50/80">
          ক্যাম্পাস তোমার বিশ্ববিদ্যালয়ের নিজের জায়গা: শেয়ার করো, প্রশ্ন করো, পোল চালাও, সমস্যা তুলে ধরো।
        </p>

        <div className="mt-8 grid gap-3 sm:grid-cols-2">
          <a
            href={intent}
            className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-white px-5 font-bold text-slate-900 shadow-lg transition hover:-translate-y-0.5"
          >
            <ExternalLink className="size-5 text-teal-700" aria-hidden />
            Open in the app
          </a>
          <a
            href={play}
            className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-white/10 px-5 font-semibold text-white ring-1 ring-white/30 transition hover:bg-white/15"
          >
            <Download className="size-5" aria-hidden />
            Get it on Google Play
          </a>
        </div>
      </div>

      <p className="mt-8 text-center text-sm text-muted-foreground">
        Only students of the same university can see its posts. Sign in with your university email (or Google).
        <span lang="bn" className="block">
          একই বিশ্ববিদ্যালয়ের শিক্ষার্থীরাই এর পোস্ট দেখতে পারে। বিশ্ববিদ্যালয়ের ইমেইল (বা Google) দিয়ে সাইন ইন করো।
        </span>
      </p>
    </section>
  );
}
