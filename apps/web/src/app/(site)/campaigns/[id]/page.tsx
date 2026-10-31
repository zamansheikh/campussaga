import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { cache } from "react";

import { type CampaignScoring, type PointKey, pointKeys, type PublicCampaign, withDefaults } from "@/lib/admin/growth";
import { publicApi } from "@/lib/public-api";
import { site } from "@/lib/site";

const idRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const getCampaign = cache((id: string) => (idRe.test(id) ? publicApi<PublicCampaign>(`/campaigns/${id}/public`) : Promise.resolve(null)));

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  const c = await getCampaign(id);
  const title = c ? `${c.titleEn}: official rules` : "Campaign rules";
  const description = `Official rules of a ${site.name} campaign.`;
  // The banner (served by ./banner/route.ts) is the link preview's picture.
  const images = c?.bannerUrl ? [{ url: `${site.url}${c.bannerUrl}`, width: 1600, height: 800, alt: c.titleEn }] : undefined;
  return {
    title,
    description,
    robots: { index: false, follow: false },
    ...(images
      ? {
          openGraph: { type: "website", siteName: site.name, title, description, url: `${site.url}/campaigns/${c?.id}`, images },
          twitter: { card: "summary_large_image", title, description, images: images.map((i) => i.url) },
        }
      : {}),
  };
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

/** A whole number in the page's language (Bangla digits in Bangla). */
function num(v: number, lang: "en" | "bn"): string {
  return lang === "bn" ? new Intl.NumberFormat("bn-BD").format(v) : String(v);
}

/** What earns [key] and how many points, in [lang]: [what, points]. */
function pointRow(key: PointKey, s: CampaignScoring, lang: "en" | "bn"): [string, string] {
  const n = (v: number) => num(v, lang);
  const p = s[key];
  if (lang === "bn") {
    switch (key) {
      case "invite":
        return [
          "তোমার লিংক দিয়ে বন্ধু যোগ দেয়, তার বিশ্ববিদ্যালয়ে ভেরিফায়েড শিক্ষার্থী হয় এবং যোগ দেওয়ার ১৪ দিনের মধ্যে ৩টি আলাদা দিনে অ্যাপ ব্যবহার করে",
          `প্রতি বন্ধুর জন্য +${n(p)}`,
        ];
      case "otherCampus":
        return ["সেই বন্ধু তোমার বিশ্ববিদ্যালয়ের নয়, অন্য বিশ্ববিদ্যালয়ে পড়ে", `সেই বন্ধুর জন্য আরও +${n(p)} পয়েন্ট`];
      case "pioneer":
        return [
          `সেই বন্ধু ভার্সিটি কথায় তার বিশ্ববিদ্যালয়ের প্রথম ${n(s.pioneerFirst)} জন ভেরিফায়েড শিক্ষার্থীর একজন`,
          `সেই বন্ধুর জন্য আরও +${n(p)} পয়েন্ট`,
        ];
      case "friendSection":
        return ["সেই বন্ধু অ্যাপে তার ক্লাসের সেকশনে যোগ দেয়", `সেই বন্ধুর জন্য আরও +${n(p)} পয়েন্ট`];
      case "joinSection":
        return ["তুমি অ্যাপে নিজের ক্লাসের সেকশনে যোগ দাও", `+${n(p)}, একবার`];
      case "bloodDonor":
        return ["তুমি রক্তদাতা হিসেবে নিবন্ধন করো", `+${n(p)}, একবার`];
      case "busShare":
        return [
          "তুমি অন্তত ১০ মিনিট লাইভ বাস শেয়ার করো এবং অন্য কোনো শিক্ষার্থী সেটা দেখে",
          `দিনে +${n(p)}, সর্বোচ্চ ${n(s.busShareDays)} দিন`,
        ];
      case "sectionSetup":
        return [
          "তুমি এমন সেকশনের সিআর, যার রুটিনে অন্তত ৫টি ক্লাস আছে এবং তুমি ছাড়া অন্তত ৫ জন ভেরিফায়েড সদস্য আছে",
          `প্রতি সেকশনের জন্য +${n(p)}, সর্বোচ্চ ${n(s.sectionSetupMax)}টি সেকশন`,
        ];
    }
  }
  switch (key) {
    case "invite":
      return [
        "A friend joins with your link, is verified as a student at their university, and uses the app on 3 different days within 14 days of joining",
        `+${n(p)} per friend`,
      ];
    case "otherCampus":
      return ["That friend studies at a different university from yours", `+${n(p)} extra points for that friend`];
    case "pioneer":
      return [`That friend is among the first ${n(s.pioneerFirst)} verified students of their university on VarsityKotha`, `+${n(p)} extra points for that friend`];
    case "friendSection":
      return ["That friend joins their class section in the app", `+${n(p)} extra points for that friend`];
    case "joinSection":
      return ["You join your own class section in the app", `+${n(p)}, once`];
    case "bloodDonor":
      return ["You register as a blood donor", `+${n(p)}, once`];
    case "busShare":
      return ["You share a live bus for at least 10 minutes and another student follows it", `+${n(p)} a day, up to ${n(s.busShareDays)} days`];
    case "sectionSetup":
      return [
        "You are the CR of a section with at least 5 classes in its routine and at least 5 verified members besides you",
        `+${n(p)} per section, up to ${n(s.sectionSetupMax)} sections`,
      ];
  }
}

/** The "How to earn points" table; rows that can't earn anything are left out. */
function PointsTable({ scoring, lang }: { scoring: CampaignScoring; lang: "en" | "bn" }) {
  // A limit of 0 days or sections means those points can't be earned.
  const keys = pointKeys.filter(
    (k) => scoring[k] > 0 && !(k === "busShare" && scoring.busShareDays === 0) && !(k === "sectionSetup" && scoring.sectionSetupMax === 0),
  );
  return (
    <table>
      <thead>
        <tr>
          <th>{lang === "bn" ? "যা করলে" : "What you do"}</th>
          <th>{lang === "bn" ? "পয়েন্ট" : "Points"}</th>
        </tr>
      </thead>
      <tbody>
        {keys.map((k) => {
          const [what, points] = pointRow(k, scoring, lang);
          return (
            <tr key={k}>
              <td>{what}</td>
              <td>
                <strong>{points}</strong>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

/** Bangla digits. */
function bn(v: number): string {
  return num(v, "bn");
}

/** "1 friend from another university who counts" / "2 friends from other universities who count". */
function otherFriends(n: number): string {
  return n === 1 ? "1 friend from another university who counts" : `${n} friends from other universities who count`;
}

/** The first sentence of a text (up to "." or "।" and the space after it). */
const firstSentence = /^[^.।]*[.।]/;

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
      "Open VarsityKotha, go to your profile and share your personal invite link with friends who study at a university in Bangladesh. You also earn points for things that make the app useful for other students, listed below. It is free to take part. There is nothing to buy, and you do not need to rate or review the app.",
    count: "How to earn points",
    countBody:
      "The extras are bonus points for that friend, added to the points for the invite. Only invites made between the start and end dates count, and they must qualify before the date above. Live bus days count only between the start and end dates. Being in a section, being a blood donor and the sections you run as CR count as they are when we choose the winners. Invites from the same phone, fake or repeated accounts, and points we find were gained unfairly are removed.",
    min: "To win a prize",
    minBody: (n: number) =>
      `To win a prize you need at least ${otherFriends(n)}: they joined with your link and qualified, as above. Only students who reach this are ranked for prizes. Until then your points still add up, and you join the ranking as soon as you reach it.`,
    whoMin: (n: number) => ` To be ranked for a prize you also need ${otherFriends(n)} (see "To win a prize").`,
    chooseMin: (n: number) => `Winners are the people with the most points, by rank, among those with at least ${otherFriends(n)}.`,
    who: "Who can take part",
    whoBody:
      "Verified VarsityKotha students in Bangladesh, at the universities this campaign covers. People who work on VarsityKotha (the team) cannot take part.",
    choose: "How winners are chosen",
    chooseBody:
      "Winners are the people with the most points, by rank. If two people have the same points, the one who reached them first ranks higher. There is no lucky draw. Before we announce winners, our team checks the standings for cheating, and may remove invites, points or people from the campaign.",
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
      "ভার্সিটি কথা খুলে প্রোফাইলে গিয়ে বাংলাদেশের বিশ্ববিদ্যালয়ে পড়া বন্ধুদের তোমার নিজের আমন্ত্রণ লিংক পাঠাও। অ্যাপকে অন্য শিক্ষার্থীদের কাজে লাগে এমন কিছু করলেও পয়েন্ট পাবে, নিচে দেওয়া আছে। অংশ নেওয়া বিনামূল্যে। কিছু কিনতে হবে না, অ্যাপে রেটিং বা রিভিউও দিতে হবে না।",
    count: "কীভাবে পয়েন্ট পাবে",
    countBody:
      "বাড়তি পয়েন্টগুলো সেই বন্ধুর জন্য বোনাস, আমন্ত্রণের পয়েন্টের সাথে যোগ হয়। শুধু শুরু ও শেষ তারিখের মধ্যে করা আমন্ত্রণ গোনা হয়, আর সেগুলো ওপরের তারিখের মধ্যে যোগ্য হতে হবে। লাইভ বাসের দিন শুধু শুরু ও শেষ তারিখের মধ্যে গোনা হয়। সেকশনে থাকা, রক্তদাতা হওয়া এবং সিআর হিসেবে তোমার সেকশনগুলো বিজয়ী বাছাইয়ের সময় যেমন থাকে, সেভাবে গোনা হয়। একই ফোন থেকে আমন্ত্রণ, ভুয়া বা বারবার খোলা অ্যাকাউন্ট এবং অন্যায়ভাবে পাওয়া পয়েন্ট বাদ দেওয়া হয়।",
    min: "পুরস্কার জিততে হলে",
    minBody: (n: number) =>
      `পুরস্কার জিততে হলে অন্য বিশ্ববিদ্যালয়ের অন্তত ${bn(n)} জন বন্ধু লাগবে, যারা গণনায় এসেছে: তোমার লিংক দিয়ে যোগ দিয়েছে এবং ওপরের নিয়মে যোগ্য হয়েছে। শুধু যারা এটা পূরণ করে, তারাই পুরস্কারের র‍্যাংকে থাকে। তার আগেও তোমার পয়েন্ট জমতে থাকে, আর পূরণ করার সঙ্গে সঙ্গেই তুমি র‍্যাংকে চলে আসবে।`,
    whoMin: (n: number) =>
      ` পুরস্কারের র‍্যাংকে থাকতে হলে অন্য বিশ্ববিদ্যালয়ের অন্তত ${bn(n)} জন গণনায় আসা বন্ধুও লাগবে ("পুরস্কার জিততে হলে" দেখো)।`,
    chooseMin: (n: number) =>
      `অন্য বিশ্ববিদ্যালয়ের অন্তত ${bn(n)} জন গণনায় আসা বন্ধু যাদের আছে, তাদের মধ্যে সবচেয়ে বেশি পয়েন্ট যাদের, তারাই র‍্যাংক অনুযায়ী বিজয়ী।`,
    who: "কারা অংশ নিতে পারবে",
    whoBody:
      "এই ক্যাম্পেইন যেসব বিশ্ববিদ্যালয়ের জন্য, বাংলাদেশের সেসবের ভেরিফায়েড ভার্সিটি কথা শিক্ষার্থীরা। ভার্সিটি কথার টিমের সদস্যরা অংশ নিতে পারবে না।",
    choose: "বিজয়ী কীভাবে ঠিক হয়",
    chooseBody:
      "সবচেয়ে বেশি পয়েন্ট যাদের, তারাই র‍্যাংক অনুযায়ী বিজয়ী। দুজনের পয়েন্ট সমান হলে যে আগে সেই পয়েন্টে পৌঁছেছে, সে এগিয়ে থাকবে। কোনো লটারি নেই। বিজয়ী ঘোষণার আগে আমাদের টিম জালিয়াতি আছে কি না দেখে, আর প্রয়োজনে আমন্ত্রণ, পয়েন্ট বা কাউকে ক্যাম্পেইন থেকে বাদ দিতে পারে।",
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
  const scoring = withDefaults(c.scoring);
  const min = scoring.minOtherCampus;
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
      <PointsTable scoring={scoring} lang={lang} />
      <p>{t.countBody}</p>
      {min > 0 ? (
        <>
          <h2>{t.min}</h2>
          <p>
            <strong>{t.minBody(min)}</strong>
          </p>
        </>
      ) : null}
      <h2>{t.who}</h2>
      <p>
        {t.whoBody}
        {min > 0 ? t.whoMin(min) : null}
      </p>
      <h2>{t.choose}</h2>
      <p>{min > 0 ? t.chooseBody.replace(firstSentence, t.chooseMin(min)) : t.chooseBody}</p>
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
      {c.bannerUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={c.bannerUrl} alt={c.titleEn} width={1600} height={800} className="mb-8 aspect-[2/1] w-full rounded-xl border bg-muted object-cover" />
      ) : null}
      <Version c={c} lang="en" />
      <Version c={c} lang="bn" />
    </article>
  );
}
