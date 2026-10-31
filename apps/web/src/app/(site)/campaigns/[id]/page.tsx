import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { cache } from "react";

import type { PublicCampaign } from "@/lib/admin/growth";
import { publicApi } from "@/lib/public-api";
import { site } from "@/lib/site";

const idRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const getCampaign = cache((id: string) => (idRe.test(id) ? publicApi<PublicCampaign>(`/campaigns/${id}/public`) : Promise.resolve(null)));

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  const c = await getCampaign(id);
  const title = c ? `${c.titleEn}: official rules` : "Campaign rules";
  return { title, description: `Official rules of a ${site.name} campaign.`, robots: { index: false, follow: false } };
}

function dhaka(iso: string, lang: "en" | "bn"): string {
  return new Intl.DateTimeFormat(lang === "bn" ? "bn-BD" : "en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZone: "Asia/Dhaka",
  }).format(new Date(iso));
}

function rankText(from: number, to: number, lang: "en" | "bn"): string {
  const n = (v: number) => (lang === "bn" ? new Intl.NumberFormat("bn-BD").format(v) : String(v));
  if (lang === "bn") return from === to ? `${n(from)} নম্বর` : `${n(from)}–${n(to)} নম্বর`;
  return from === to ? `Rank ${n(from)}` : `Ranks ${n(from)}–${n(to)}`;
}

/** Text from the API with its line breaks, as plain text (React escapes it; no HTML is ever injected). */
function Text({ children }: { children: string }) {
  if (!children.trim()) return null;
  return <p className="whitespace-pre-line">{children}</p>;
}

const copy = {
  en: {
    prizes: "Prizes",
    when: "When",
    starts: "Starts",
    ends: "Ends",
    settles: "Invites can still qualify until",
    take: "How to take part",
    takeBody:
      "Open VarsityKotha, go to your profile and share your personal invite link with friends who study at a university in Bangladesh. It is free to take part. There is nothing to buy, and you do not need to rate or review the app.",
    count: "How invites count",
    countBody:
      "An invite counts once, when your friend joins with your link, is verified as a student at their university, and uses the app on 3 different days within 14 days of joining. Only invites made between the start and end dates count, and they must qualify before the date above. Invites from the same phone, fake or repeated accounts, and invites we find were gained unfairly are removed.",
    who: "Who can take part",
    whoBody:
      "Verified VarsityKotha students in Bangladesh, at the universities this campaign covers. People who work on VarsityKotha (the team) cannot take part.",
    choose: "How winners are chosen",
    chooseBody:
      "Winners are the people with the most qualifying invites, by rank. There is no lucky draw. Before we announce winners, our team checks the standings for cheating, and may remove invites or people from the campaign.",
    deliver: "How prizes are delivered",
    deliverBody:
      "Winners get a message in the app and send us their name, phone number and address there. We deliver the prize to that address. We use these details only to deliver the prize and delete them 90 days after delivery.",
    google: "This campaign is not sponsored by Google.",
    contact: "Questions",
    rules: "Campaign rules",
  },
  bn: {
    prizes: "পুরস্কার",
    when: "সময়",
    starts: "শুরু",
    ends: "শেষ",
    settles: "এই সময় পর্যন্ত আমন্ত্রণ গণনায় আসতে পারে",
    take: "কীভাবে অংশ নেবে",
    takeBody:
      "ভার্সিটি কথা খুলে প্রোফাইলে গিয়ে বাংলাদেশের বিশ্ববিদ্যালয়ে পড়া বন্ধুদের তোমার নিজের আমন্ত্রণ লিংক পাঠাও। অংশ নেওয়া বিনামূল্যে। কিছু কিনতে হবে না, অ্যাপে রেটিং বা রিভিউও দিতে হবে না।",
    count: "আমন্ত্রণ কীভাবে গোনা হয়",
    countBody:
      "তোমার লিংক দিয়ে বন্ধু যোগ দিলে, তার বিশ্ববিদ্যালয়ে ভেরিফায়েড শিক্ষার্থী হলে এবং যোগ দেওয়ার ১৪ দিনের মধ্যে ৩ দিন আলাদা আলাদা দিনে অ্যাপ ব্যবহার করলে আমন্ত্রণটি একবার গোনা হয়। শুধু শুরু ও শেষ তারিখের মধ্যে করা আমন্ত্রণ গোনা হয়, আর সেগুলো ওপরের তারিখের মধ্যে যোগ্য হতে হবে। একই ফোন থেকে আমন্ত্রণ, ভুয়া বা বারবার খোলা অ্যাকাউন্ট এবং অন্যায়ভাবে পাওয়া আমন্ত্রণ বাদ দেওয়া হয়।",
    who: "কারা অংশ নিতে পারবে",
    whoBody:
      "এই ক্যাম্পেইন যেসব বিশ্ববিদ্যালয়ের জন্য, বাংলাদেশের সেসবের ভেরিফায়েড ভার্সিটি কথা শিক্ষার্থীরা। ভার্সিটি কথার টিমের সদস্যরা অংশ নিতে পারবে না।",
    choose: "বিজয়ী কীভাবে ঠিক হয়",
    chooseBody:
      "সবচেয়ে বেশি যোগ্য আমন্ত্রণ যাদের, তারাই র‍্যাংক অনুযায়ী বিজয়ী। কোনো লটারি নেই। বিজয়ী ঘোষণার আগে আমাদের টিম জালিয়াতি আছে কি না দেখে, আর প্রয়োজনে আমন্ত্রণ বা কাউকে ক্যাম্পেইন থেকে বাদ দিতে পারে।",
    deliver: "পুরস্কার কীভাবে পৌঁছায়",
    deliverBody:
      "বিজয়ীরা অ্যাপে বার্তা পায় এবং সেখানে নিজের নাম, ফোন নম্বর ও ঠিকানা পাঠায়। আমরা সেই ঠিকানায় পুরস্কার পাঠাই। এই তথ্য শুধু পুরস্কার পাঠাতে ব্যবহার হয় এবং পৌঁছানোর ৯০ দিন পর মুছে ফেলা হয়।",
    google: "এই ক্যাম্পেইনের স্পনসর Google নয়।",
    contact: "প্রশ্ন",
    rules: "ক্যাম্পেইনের নিয়ম",
  },
};

function Version({ c, lang }: { c: PublicCampaign; lang: "en" | "bn" }) {
  const t = copy[lang];
  const title = lang === "bn" ? c.titleBn || c.titleEn : c.titleEn || c.titleBn;
  const body = lang === "bn" ? c.bodyBn || c.bodyEn : c.bodyEn || c.bodyBn;
  const rules = lang === "bn" ? c.rulesBn || c.rulesEn : c.rulesEn || c.rulesBn;
  const prizes = c.prizes ?? [];
  return (
    <section lang={lang} id={lang === "bn" ? "bn" : undefined} className={lang === "bn" ? "mt-16 border-t-2 pt-10" : undefined}>
      <h1>{title}</h1>
      <p className="text-muted-foreground">{t.rules}</p>
      {lang === "en" ? (
        <p>
          <a href="#bn">বাংলায় পড়ো</a>
        </p>
      ) : null}
      <Text>{body}</Text>

      <h2>{t.when}</h2>
      <ul>
        <li>
          <strong>{t.starts}:</strong> {dhaka(c.startsAt, lang)} {lang === "bn" ? "(বাংলাদেশ সময়)" : "(Bangladesh time)"}
        </li>
        <li>
          <strong>{t.ends}:</strong> {dhaka(c.endsAt, lang)}
        </li>
        <li>
          <strong>{t.settles}:</strong> {dhaka(c.settlesAt, lang)}
        </li>
      </ul>

      {prizes.length > 0 ? (
        <>
          <h2>{t.prizes}</h2>
          <ul>
            {prizes.map((p, i) => (
              <li key={i}>
                <strong>{rankText(p.rankFrom, p.rankTo, lang)}:</strong> {lang === "bn" ? p.titleBn || p.titleEn : p.titleEn || p.titleBn}
              </li>
            ))}
          </ul>
        </>
      ) : null}

      <h2>{t.take}</h2>
      <p>{t.takeBody}</p>
      <h2>{t.count}</h2>
      <p>{t.countBody}</p>
      <h2>{t.who}</h2>
      <p>{t.whoBody}</p>
      <h2>{t.choose}</h2>
      <p>{t.chooseBody}</p>
      <h2>{t.deliver}</h2>
      <p>{t.deliverBody}</p>

      {rules.trim() ? (
        <>
          <h2>{t.rules}</h2>
          <Text>{rules}</Text>
        </>
      ) : null}

      <p>
        <strong>{t.google}</strong>
      </p>
      <h2>{t.contact}</h2>
      <p>
        {lang === "bn" ? "সিলিফটন" : "Silifton"} · <a href={`mailto:${site.supportEmail}`}>{site.supportEmail}</a> ·{" "}
        <a href={site.company.url}>silifton.com</a>
      </p>
    </section>
  );
}

/** The public official rules of a prize campaign, in English and Bangla (the app links here). */
export default async function CampaignRulesPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const c = await getCampaign(id);
  if (!c) notFound();
  return (
    <article className="prose-page mx-auto max-w-3xl px-4 py-12">
      <Version c={c} lang="en" />
      <Version c={c} lang="bn" />
    </article>
  );
}
