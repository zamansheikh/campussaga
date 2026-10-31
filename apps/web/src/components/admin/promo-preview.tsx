"use client";

import { Check, Copy, ExternalLink, ImageIcon, Info, MoreVertical, Search, Trophy } from "lucide-react";
import { useState } from "react";

import { cn } from "@/lib/utils";
import type { PromoKind, PromoPlacement } from "@/lib/admin/sponsors";

/** What the preview draws; texts fall back from Bangla to English, as in the app. */
export type PreviewData = {
  kind: PromoKind;
  placement: PromoPlacement;
  sponsorName: string;
  sponsorLogoUrl?: string | null;
  titleEn: string;
  titleBn: string;
  bodyEn: string;
  bodyBn: string;
  ctaEn: string;
  ctaBn: string;
  imageUrl?: string | null;
  code: string;
  expiresAt: string | null;
  termsEn: string;
  termsBn: string;
  hasLink: boolean;
  campaignTitle?: string;
};

type Lang = "en" | "bn";
type Theme = "light" | "dark";

/** The app's colours (campus_ui CsColors), so the preview matches the phone. */
const palettes: Record<Theme, Record<string, string>> = {
  light: {
    "--p-bg": "#F8FAFC",
    "--p-surface": "#FFFFFF",
    "--p-variant": "#F1F5F9",
    "--p-text": "#0F172A",
    "--p-text2": "#475569",
    "--p-border": "#E2E8F0",
    "--p-primary": "#0F766E",
    "--p-on-primary": "#FFFFFF",
    "--p-container": "#CCFBF1",
    "--p-on-container": "#042F2E",
    "--p-amber": "#B45309",
    "--p-amber-soft": "#FEF3C7",
    "--p-skeleton": "#E2E8F0",
  },
  dark: {
    "--p-bg": "#0B1220",
    "--p-surface": "#111A2B",
    "--p-variant": "#1E293B",
    "--p-text": "#F1F5F9",
    "--p-text2": "#94A3B8",
    "--p-border": "#273449",
    "--p-primary": "#5EEAD4",
    "--p-on-primary": "#042F2E",
    "--p-container": "#134E4A",
    "--p-on-container": "#CCFBF1",
    "--p-amber": "#FBBF24",
    "--p-amber-soft": "#451A03",
    "--p-skeleton": "#1E293B",
  },
};

const english = {
  sponsored: "Sponsored",
  supportedBy: "Supported by",
  poweredBy: "Powered by",
  copy: "Copy",
  copied: "Copied",
  expires: "Valid till",
  terms: "Terms",
  visit: "Visit",
  deals: "Student deals",
  search: "Search deals",
  announcements: "ANNOUNCEMENTS",
  today: "Today",
  nearYou: "NEAR YOU",
  button: "Learn more",
  topPrize: "Top prize: Smartphone",
  live: "LIVE · 4d left",
};

const words: Record<Lang, typeof english> = {
  en: english,
  bn: {
    sponsored: "স্পন্সরড",
    supportedBy: "সহযোগিতায়",
    poweredBy: "সহযোগিতায়",
    copy: "কপি",
    copied: "কপি হয়েছে",
    expires: "মেয়াদ",
    terms: "শর্ত",
    visit: "দেখো",
    deals: "স্টুডেন্ট ডিল",
    search: "ডিল খোঁজো",
    announcements: "ঘোষণা",
    today: "আজ",
    nearYou: "তোমার কাছে",
    button: "আরও জানো",
    topPrize: "সেরা পুরস্কার: স্মার্টফোন",
    live: "লাইভ · ৪ দিন বাকি",
  },
};

function pick(lang: Lang, en: string, bn: string): string {
  return lang === "bn" && bn.trim() ? bn : en;
}

function dateText(iso: string, lang: Lang): string {
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return "";
  return new Intl.DateTimeFormat(lang === "bn" ? "bn-BD" : "en-GB", { day: "numeric", month: "short", timeZone: "Asia/Dhaka" }).format(t);
}

/**
 * The ad as the app draws it, inside a phone-width frame with a hint of the
 * screen around it, in light or dark and English or Bangla.
 */
export function PromoPreview({ data, className }: { data: PreviewData; className?: string }) {
  const [theme, setTheme] = useState<Theme>("dark");
  const [lang, setLang] = useState<Lang>("en");
  return (
    <div className={cn("space-y-3", className)}>
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-sm font-medium">Preview</p>
        <div className="flex gap-2">
          <Segmented
            label="Theme"
            value={theme}
            onChange={setTheme}
            options={[
              { value: "light", label: "Light" },
              { value: "dark", label: "Dark" },
            ]}
          />
          <Segmented
            label="Language"
            value={lang}
            onChange={setLang}
            options={[
              { value: "en", label: "English" },
              { value: "bn", label: "বাংলা" },
            ]}
          />
        </div>
      </div>
      <div
        lang={lang}
        style={palettes[theme] as React.CSSProperties}
        className="mx-auto w-full max-w-[360px] overflow-hidden rounded-[32px] border-[6px] border-neutral-800 bg-[var(--p-bg)] text-[var(--p-text)] shadow-xl dark:border-neutral-700"
      >
        <div className="flex h-6 items-center justify-center" aria-hidden>
          <span className="h-1.5 w-16 rounded-full bg-[var(--p-skeleton)]" />
        </div>
        <div className="px-4 pt-2 pb-6">
          <Screen data={data} lang={lang} />
        </div>
      </div>
      <p className="text-center text-xs text-muted-foreground">Drawn like the app; exact fonts and spacing can differ slightly on a phone.</p>
    </div>
  );
}

function Segmented<T extends string>({
  label,
  value,
  onChange,
  options,
}: {
  label: string;
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: string }[];
}) {
  return (
    <div role="radiogroup" aria-label={label} className="inline-flex rounded-lg border bg-muted p-0.5 text-xs">
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={value === o.value}
          onClick={() => onChange(o.value)}
          className={cn(
            "rounded-md px-2.5 py-1 font-medium transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
            value === o.value ? "bg-background text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground",
          )}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

/** A muted bar standing in for the app content around the ad. */
function Bar({ w, h = "h-3", className }: { w: string; h?: string; className?: string }) {
  return <span aria-hidden className={cn("block rounded-full bg-[var(--p-skeleton)]", h, w, className)} />;
}

function GhostCard({ lines = 2 }: { lines?: number }) {
  return (
    <div aria-hidden className="space-y-2.5 rounded-[20px] border border-[var(--p-border)] bg-[var(--p-surface)] p-4 opacity-70">
      <div className="flex items-center gap-3">
        <span className="size-9 rounded-full bg-[var(--p-skeleton)]" />
        <div className="flex-1 space-y-1.5">
          <Bar w="w-1/2" />
          <Bar w="w-1/3" h="h-2.5" />
        </div>
      </div>
      {Array.from({ length: lines }, (_, i) => (
        <Bar key={i} w={i === lines - 1 ? "w-2/3" : "w-full"} />
      ))}
    </div>
  );
}

function Logo({ url, name, size }: { url?: string | null; name: string; size: number }) {
  const initials =
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((w) => w[0]?.toUpperCase() ?? "")
      .join("") || "?";
  return url ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={url} alt="" style={{ width: size, height: size }} className="shrink-0 rounded-full bg-white object-contain" />
  ) : (
    <span
      style={{ width: size, height: size, fontSize: Math.max(9, size * 0.38) }}
      className="inline-flex shrink-0 items-center justify-center rounded-full bg-[var(--p-container)] font-semibold text-[var(--p-on-container)]"
    >
      {initials}
    </span>
  );
}

function Picture({ url, className }: { url?: string | null; className?: string }) {
  return url ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={url} alt="" className={cn("aspect-[2/1] w-full object-cover", className)} />
  ) : (
    <div className={cn("flex aspect-[2/1] w-full flex-col items-center justify-center gap-1 bg-[var(--p-variant)] text-xs text-[var(--p-text2)]", className)}>
      <ImageIcon className="size-6" aria-hidden />
      Image 2:1
    </div>
  );
}

function SponsoredLabel({ name, lang }: { name: string; lang: Lang }) {
  return (
    <span className="flex min-w-0 items-center gap-1 text-[12px] text-[var(--p-text2)]">
      <span className="truncate">
        {words[lang].sponsored} · {name || "Brand"}
      </span>
      <Info className="size-3.5 shrink-0" aria-label="Why am I seeing this?" />
    </span>
  );
}

function AppButton({ label, tonal = false }: { label: string; tonal?: boolean }) {
  return (
    <span
      className={cn(
        "inline-flex h-9 items-center justify-center rounded-full px-4 text-[14px] font-medium",
        tonal ? "bg-[var(--p-container)] text-[var(--p-on-container)]" : "bg-[var(--p-primary)] text-[var(--p-on-primary)]",
      )}
    >
      {label}
    </span>
  );
}

function Screen({ data, lang }: { data: PreviewData; lang: Lang }) {
  const w = words[lang];
  const title = pick(lang, data.titleEn, data.titleBn);
  const body = pick(lang, data.bodyEn, data.bodyBn);
  const cta = pick(lang, data.ctaEn, data.ctaBn) || w.button;
  const name = data.sponsorName || "Brand";

  if (data.kind === "card") {
    return (
      <div className="space-y-4">
        <div aria-hidden className="space-y-1.5 pt-1">
          <Bar w="w-24" h="h-2.5" className="bg-[var(--p-primary)] opacity-60" />
          <Bar w="w-44" h="h-5" />
        </div>
        <GhostCard lines={2} />
        <article className="overflow-hidden rounded-[20px] border border-[var(--p-border)] bg-[var(--p-surface)]">
          <Picture url={data.imageUrl} />
          <div className="space-y-1 p-4">
            <div className="flex items-center justify-between gap-2">
              <SponsoredLabel name={name} lang={lang} />
              <MoreVertical className="size-4 shrink-0 text-[var(--p-text2)]" aria-hidden />
            </div>
            <h3 className="text-[16px] leading-snug font-semibold">{title || "Your title"}</h3>
            {body ? <p className="line-clamp-2 text-[14px] leading-snug text-[var(--p-text2)]">{body}</p> : null}
            {data.hasLink ? (
              <div className="pt-2">
                <AppButton label={cta} />
              </div>
            ) : null}
          </div>
        </article>
        <p aria-hidden className="px-1 text-[12px] font-semibold tracking-wider text-[var(--p-text2)]">
          {w.announcements}
        </p>
        <GhostCard lines={1} />
      </div>
    );
  }

  if (data.kind === "feed") {
    return (
      <div className="space-y-3">
        <GhostCard lines={2} />
        <article className="space-y-3 rounded-[20px] border border-[var(--p-border)] bg-[var(--p-surface)] p-4">
          <div className="flex items-center gap-3">
            <Logo url={data.sponsorLogoUrl} name={name} size={40} />
            <div className="min-w-0 flex-1">
              <p className="truncate text-[15px] font-semibold">{name}</p>
              <p className="flex items-center gap-1 text-[12px] text-[var(--p-text2)]">
                {w.sponsored} <Info className="size-3" aria-hidden />
              </p>
            </div>
            <MoreVertical className="size-4 shrink-0 text-[var(--p-text2)]" aria-hidden />
          </div>
          <div className="space-y-1">
            <h3 className="text-[16px] leading-snug font-semibold">{title || "Your title"}</h3>
            {body ? <p className="text-[14px] leading-snug">{body}</p> : null}
          </div>
          <Picture url={data.imageUrl} className="rounded-[14px]" />
          {data.hasLink ? (
            <div className="flex">
              <span className="inline-flex h-9 w-full items-center justify-center rounded-full bg-[var(--p-container)] text-[14px] font-medium text-[var(--p-on-container)]">
                {cta}
              </span>
            </div>
          ) : null}
        </article>
        <GhostCard lines={1} />
      </div>
    );
  }

  if (data.kind === "deal") {
    return (
      <div className="space-y-3">
        <div className="flex items-center gap-3 pt-1">
          <span aria-hidden className="text-[20px]">
            ←
          </span>
          <h2 className="text-[20px] font-semibold">{w.deals}</h2>
        </div>
        <div className="flex h-10 items-center gap-2 rounded-full bg-[var(--p-variant)] px-4 text-[14px] text-[var(--p-text2)]" aria-hidden>
          <Search className="size-4" /> {w.search}
        </div>
        <p aria-hidden className="px-1 pt-1 text-[12px] font-semibold tracking-wider text-[var(--p-text2)]">
          {w.nearYou}
        </p>
        <DealCard data={data} lang={lang} title={title} body={body} name={name} />
        <GhostCard lines={2} />
      </div>
    );
  }

  if (data.kind === "line") {
    const lead = pick(lang, data.titleEn, data.titleBn) || w.supportedBy;
    return (
      <div className="space-y-3">
        <div aria-hidden className="pt-1">
          <Bar w="w-36" h="h-5" />
        </div>
        <GhostCard lines={1} />
        <GhostCard lines={1} />
        <div className="flex flex-wrap items-center justify-center gap-x-1.5 gap-y-1 px-2 py-3 text-center text-[12px] text-[var(--p-text2)]">
          <span>{lead}</span>
          <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
            <Logo url={data.sponsorLogoUrl} name={name} size={20} />
            <span className="font-semibold text-[var(--p-text)]">{name}</span>
            {data.hasLink ? <ExternalLink className="size-3" aria-hidden /> : null}
          </span>
        </div>
      </div>
    );
  }

  // campaign: the poster with "Powered by" at its bottom right.
  return (
    <div className="space-y-3">
      <div className="relative overflow-hidden rounded-[20px] bg-[linear-gradient(135deg,#0F766E,#134E4A_45%,#1E1B4B)] p-4 text-white">
        <span className="inline-flex rounded-full border border-white/40 bg-white/20 px-2.5 py-0.5 text-[11px] font-bold tracking-wide">{w.live}</span>
        <Trophy className="absolute top-5 right-5 size-12 text-amber-300/80" aria-hidden />
        <h3 className="mt-10 max-w-[70%] text-[19px] leading-tight font-extrabold">{data.campaignTitle || "Invite & win"}</h3>
        <div className="mt-2 flex items-end justify-between gap-2">
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-400 px-2.5 py-0.5 text-[11px] font-extrabold text-amber-950">
            <Trophy className="size-3" aria-hidden /> {w.topPrize}
          </span>
          <span className="inline-flex shrink-0 items-center gap-1.5 rounded-full bg-black/35 py-0.5 ps-2 pe-1 text-[11px] backdrop-blur">
            {w.poweredBy}
            <Logo url={data.sponsorLogoUrl} name={name} size={18} />
            <span className="max-w-24 truncate pe-1 font-semibold">{name}</span>
          </span>
        </div>
      </div>
      <GhostCard lines={2} />
    </div>
  );
}

function DealCard({ data, lang, title, body, name }: { data: PreviewData; lang: Lang; title: string; body: string; name: string }) {
  const w = words[lang];
  const [copied, setCopied] = useState(false);
  const terms = pick(lang, data.termsEn, data.termsBn);
  const expiry = data.expiresAt ? dateText(data.expiresAt, lang) : "";
  return (
    <article className="space-y-3 rounded-[20px] border border-[var(--p-border)] bg-[var(--p-surface)] p-4">
      <div className="flex items-start gap-3">
        {data.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={data.imageUrl} alt="" className="size-12 shrink-0 rounded-[14px] object-cover" />
        ) : (
          <span className="shrink-0 overflow-hidden rounded-[14px]">
            <Logo url={data.sponsorLogoUrl} name={name} size={48} />
          </span>
        )}
        <div className="min-w-0 flex-1">
          <p className="flex items-center justify-between gap-2 text-[12px] text-[var(--p-text2)]">
            <span className="truncate">{name}</span>
            <span className="shrink-0">{w.sponsored}</span>
          </p>
          <h3 className="text-[16px] leading-snug font-semibold">{title || "Your offer"}</h3>
          {body ? <p className="mt-0.5 text-[13px] leading-snug text-[var(--p-text2)]">{body}</p> : null}
        </div>
      </div>
      {data.code ? (
        <div className="flex items-center gap-2">
          <span className="min-w-0 flex-1 truncate rounded-[10px] border border-dashed border-[var(--p-amber)] bg-[var(--p-amber-soft)] px-3 py-1.5 font-mono text-[14px] font-bold tracking-wider text-[var(--p-amber)]">
            {data.code}
          </span>
          <button
            type="button"
            onClick={() => {
              void navigator.clipboard?.writeText(data.code).catch(() => {});
              setCopied(true);
              setTimeout(() => setCopied(false), 1500);
            }}
            className="inline-flex h-9 items-center gap-1.5 rounded-full bg-[var(--p-primary)] px-3.5 text-[13px] font-medium text-[var(--p-on-primary)]"
          >
            {copied ? <Check className="size-4" aria-hidden /> : <Copy className="size-4" aria-hidden />}
            {copied ? w.copied : w.copy}
          </button>
        </div>
      ) : null}
      <div className="flex items-center justify-between gap-2 text-[12px] text-[var(--p-text2)]">
        <span>{expiry ? `${w.expires} ${expiry}` : ""}</span>
        {data.hasLink ? (
          <span className="inline-flex items-center gap-1 font-medium text-[var(--p-primary)]">
            {w.visit} <ExternalLink className="size-3" aria-hidden />
          </span>
        ) : null}
      </div>
      {terms ? (
        <details className="group text-[12px] text-[var(--p-text2)]">
          <summary className="cursor-pointer font-medium text-[var(--p-text)] select-none">{w.terms}</summary>
          <p className="mt-1 whitespace-pre-line">{terms}</p>
        </details>
      ) : null}
    </article>
  );
}
