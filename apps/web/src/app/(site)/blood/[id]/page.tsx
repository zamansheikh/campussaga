import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Download, Droplet, ExternalLink } from "lucide-react";

import { BrandMark } from "@/components/site/brand-mark";
import { playUrl, site } from "@/lib/site";

export const metadata: Metadata = {
  title: "A blood request",
  description: `Someone at a university on ${site.name} needs blood. Open it in the app to see the details and offer to donate.`,
  robots: { index: false, follow: false },
};

const idRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Where a shared blood request link lands when the app isn't installed (or
 * the link opened in a browser). The shared message already carries the
 * details; this page only leads to the app, where donors can respond.
 */
export default async function SharedBloodRequestPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!idRe.test(id)) notFound();
  const play = playUrl();
  const intent = `intent://varsitykotha.com/blood/${id}#Intent;scheme=https;package=${site.androidPackage};S.browser_fallback_url=${encodeURIComponent(play)};end`;

  return (
    <section className="mx-auto max-w-xl px-4 py-12 sm:py-16">
      <div className="overflow-hidden rounded-[2rem] bg-[linear-gradient(160deg,#ef4444_0%,#c62828_45%,#7f1d1d_100%)] p-8 text-center text-white shadow-xl sm:p-10">
        <div className="mx-auto flex size-16 items-center justify-center rounded-full bg-white/15 ring-1 ring-white/30">
          <Droplet className="size-8" aria-hidden />
        </div>
        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">Someone needs blood</h1>
        <p lang="bn" className="mt-1 text-lg font-semibold text-red-50/90">
          একজনের রক্ত প্রয়োজন
        </p>
        <p className="mt-4 text-red-50/90">
          Open the request in {site.name} to see the details, call the family and offer to donate.
        </p>
        <p lang="bn" className="mt-1 text-sm text-red-50/80">
          বিস্তারিত দেখতে, পরিবারকে কল করতে আর রক্ত দিতে চাইলে অনুরোধটি ভার্সিটি কথায় খোলো।
        </p>

        <div className="mt-8 grid gap-3 sm:grid-cols-2">
          <a
            href={intent}
            className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-white px-5 font-bold text-slate-900 shadow-lg transition hover:-translate-y-0.5"
          >
            <ExternalLink className="size-5 text-red-700" aria-hidden />
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

      <div className="mt-8 flex items-center justify-center gap-2 text-sm text-muted-foreground">
        <BrandMark className="size-6 rounded-[22%]" />
        <span>
          Requests are visible to students of the same university.
          <span lang="bn" className="block">
            একই বিশ্ববিদ্যালয়ের শিক্ষার্থীরা অনুরোধগুলো দেখতে পারে।
          </span>
        </span>
      </div>
    </section>
  );
}
