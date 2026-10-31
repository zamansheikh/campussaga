import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Download, ExternalLink, UserCheck } from "lucide-react";

import { BrandMark } from "@/components/site/brand-mark";
import { ApiError } from "@/lib/admin/errors";
import { callApi } from "@/lib/admin/tokens";
import { playUrl, site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Confirm a classmate",
  description: `A student asked you to confirm they study at their university on ${site.name}. Open the link in the app to vouch.`,
  robots: { index: false, follow: false },
};

const codeRe = /^[a-z0-9]{8}$/;

type Vouch = { student: { name: string | null }; university: { name: string } };

/** The student's name and university, without signing in; null when the API needs a sign-in for it. */
async function lookup(code: string): Promise<Vouch | null> {
  try {
    const v = await callApi<Vouch>(`/vouch/${code}`);
    return v?.student && v?.university ? v : null;
  } catch (e) {
    if (e instanceof ApiError && e.code === "VOUCH_NOT_FOUND") notFound();
    return null;
  }
}

/**
 * Where a vouch link lands when the app isn't installed (or the link opened
 * in a browser). It shows only the student's name and university; the vouch
 * itself happens in the app, where the classmate is signed in.
 */
export default async function VouchPage({ params }: { params: Promise<{ code: string }> }) {
  const { code: raw } = await params;
  const code = raw.toLowerCase();
  if (!codeRe.test(code)) notFound();
  const v = await lookup(code);
  const play = playUrl();
  const intent = `intent://varsitykotha.com/v/${code}#Intent;scheme=https;package=${site.androidPackage};S.browser_fallback_url=${encodeURIComponent(play)};end`;
  const name = v?.student.name?.trim() || "A classmate";

  return (
    <section className="mx-auto max-w-xl px-4 py-12 sm:py-16">
      <div className="overflow-hidden rounded-[2rem] bg-[linear-gradient(160deg,#14b8a6_0%,#0f9488_40%,#0b5e57_100%)] p-8 text-center text-white shadow-xl sm:p-10">
        <div className="mx-auto flex size-16 items-center justify-center rounded-full bg-white/15 ring-1 ring-white/30">
          <UserCheck className="size-8" aria-hidden />
        </div>
        {v ? (
          <>
            <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">
              {name} asked you to confirm they study at {v.university.name}.
            </h1>
            <p lang="bn" className="mt-2 text-lg font-semibold text-teal-50/90">
              {name} জানতে চেয়েছে তুমি নিশ্চিত করবে কি না যে সে {v.university.name}-এ পড়ে।
            </p>
          </>
        ) : (
          <>
            <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-balance sm:text-3xl">Open this link in the VarsityKotha app to vouch</h1>
            <p lang="bn" className="mt-2 text-lg font-semibold text-teal-50/90">
              নিশ্চিত করতে এই লিংকটি ভার্সিটি কথা অ্যাপে খোলো
            </p>
          </>
        )}
        <p className="mt-4 text-teal-50/85">Only confirm someone you know studies there. You need to be verified at the same university.</p>
        <p lang="bn" className="mt-1 text-sm text-teal-50/80">
          যাকে চেনো আর যে ওখানে পড়ে, শুধু তাকেই নিশ্চিত করো। তোমাকেও একই বিশ্ববিদ্যালয়ে ভেরিফায়েড হতে হবে।
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
            Get VarsityKotha
          </a>
        </div>
      </div>

      <div className="mt-8 flex items-center justify-center gap-2 text-sm text-muted-foreground">
        <BrandMark className="size-6 rounded-[22%]" />
        <span>Two verified classmates can confirm a student who has no university email.</span>
      </div>
    </section>
  );
}
