"use client";

import { BadgePercent, Columns2, Info, Loader2, Megaphone, Newspaper, Rows3, Trophy, X } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useState, useTransition } from "react";
import { toast } from "sonner";

import { ImageUploadField } from "@/components/admin/image-upload-field";
import { PromoPreview, type PreviewData } from "@/components/admin/promo-preview";
import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { fromDhakaInput, toDhakaInput } from "@/lib/admin/growth";
import {
  type AdminPromo,
  type AdminSponsor,
  appRoutes,
  CAMPAIGN_ROUTE,
  categoryLabel,
  kindInfo,
  kindNeeds,
  kindOrder,
  limits,
  type LinkKind,
  placementLabel,
  placementsFor,
  type PromoKind,
  type PromoPlacement,
} from "@/lib/admin/sponsors";
import { cn } from "@/lib/utils";

import { removePromoImage, savePromo } from "./actions";

export type CampaignOption = { id: string; titleEn: string; status: string };
export type UniversityWithCity = UniversityOption & { city: string | null };

const kindIcon: Record<PromoKind, React.ComponentType<{ className?: string }>> = {
  deal: BadgePercent,
  card: Columns2,
  feed: Newspaper,
  line: Rows3,
  campaign: Trophy,
};

const DAY = 24 * 3600_000;
const CAMPAIGN_PLACEHOLDER = "/campaigns/{id}";

function numberOrNaN(v: string): number {
  return v.trim() === "" ? Number.NaN : Number(v);
}

/**
 * Create or edit an ad, with a live preview of how the app draws it. While
 * an ad is live only its end, total views, times a day and priority can
 * change; an ended ad can only be duplicated.
 */
export function AdForm({
  promo,
  sponsors,
  universities,
  campaigns,
  initialSponsorId,
  initialKind,
}: {
  promo?: AdminPromo;
  sponsors: AdminSponsor[];
  universities: UniversityWithCity[];
  campaigns: CampaignOption[];
  initialSponsorId?: string;
  initialKind?: PromoKind;
}) {
  const router = useRouter();
  const live = promo?.status === "live";
  const ended = promo?.status === "ended";
  const locked = live || ended;

  const [sponsorId, setSponsorId] = useState(promo?.sponsorId ?? initialSponsorId ?? "");
  const [kind, setKind] = useState<PromoKind>(promo?.kind ?? initialKind ?? "card");
  const [placement, setPlacement] = useState<PromoPlacement>(promo?.placement ?? placementsFor[initialKind ?? "card"][0]!);
  const [campaignId, setCampaignId] = useState(promo?.campaignId ?? "");
  const [titleEn, setTitleEn] = useState(promo?.titleEn ?? "");
  const [titleBn, setTitleBn] = useState(promo?.titleBn ?? "");
  const [bodyEn, setBodyEn] = useState(promo?.bodyEn ?? "");
  const [bodyBn, setBodyBn] = useState(promo?.bodyBn ?? "");
  const [ctaEn, setCtaEn] = useState(promo?.ctaEn ?? "");
  const [ctaBn, setCtaBn] = useState(promo?.ctaBn ?? "");
  const [linkKind, setLinkKind] = useState<LinkKind>(promo?.linkKind ?? "none");
  const initialLink = promo?.link ?? "";
  const [webLink, setWebLink] = useState(promo?.linkKind === "web" ? initialLink : "");
  const [appRoute, setAppRoute] = useState(
    promo?.linkKind === "app" ? (CAMPAIGN_ROUTE.test(initialLink) ? CAMPAIGN_PLACEHOLDER : initialLink) : "/deals",
  );
  const [linkCampaignId, setLinkCampaignId] = useState(CAMPAIGN_ROUTE.exec(initialLink)?.[1] ?? "");
  const [code, setCode] = useState(promo?.code ?? "");
  const [expiresAt, setExpiresAt] = useState(promo?.expiresAt ? toDhakaInput(promo.expiresAt) : "");
  const [termsEn, setTermsEn] = useState(promo?.termsEn ?? "");
  const [termsBn, setTermsBn] = useState(promo?.termsBn ?? "");
  const [everyone, setEveryone] = useState(!promo || (promo.universityIds == null && promo.cities == null));
  const [uniIds, setUniIds] = useState<string[]>(promo?.universityIds ?? []);
  const [cities, setCities] = useState<string[]>(promo?.cities ?? []);
  // A new ad starts in an hour and runs 30 days.
  const [startsAt, setStartsAt] = useState(() => toDhakaInput(promo?.startsAt ?? new Date(Date.now() + 3600_000).toISOString()));
  const [endsAt, setEndsAt] = useState(() => toDhakaInput(promo?.endsAt ?? new Date(Date.now() + 30 * DAY).toISOString()));
  const [dailyCap, setDailyCap] = useState(String(promo?.dailyCap ?? 2));
  const [totalViews, setTotalViews] = useState(promo?.totalViews ? String(promo.totalViews) : "");
  const [priority, setPriority] = useState(String(promo?.priority ?? 5));
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  const needs = kindNeeds[kind];
  const sponsor = sponsors.find((s) => s.id === sponsorId);
  const health = sponsor?.category === "health";
  const unis = useMemo(() => new Map(universities.map((u) => [u.id, u.name])), [universities]);
  const allCities = useMemo(
    () => [...new Set(universities.map((u) => u.city?.trim()).filter((c): c is string => Boolean(c)))].sort((a, b) => a.localeCompare(b)),
    [universities],
  );
  const link = linkKind === "web" ? webLink.trim() : linkKind === "app" ? (appRoute === CAMPAIGN_PLACEHOLDER ? (linkCampaignId ? `/campaigns/${linkCampaignId}` : "") : appRoute) : "";

  function changeKind(k: PromoKind) {
    setKind(k);
    setPlacement(placementsFor[k][0]!);
  }

  const preview: PreviewData = {
    kind,
    placement,
    sponsorName: sponsor?.name ?? promo?.sponsor?.name ?? "",
    sponsorLogoUrl: sponsor?.logoUrl ?? promo?.sponsor?.logoUrl ?? null,
    titleEn,
    titleBn,
    bodyEn,
    bodyBn,
    ctaEn,
    ctaBn,
    imageUrl: promo?.imageUrl ?? null,
    code: code.trim(),
    expiresAt: expiresAt ? fromDhakaInput(expiresAt) || null : null,
    termsEn,
    termsBn,
    hasLink: linkKind !== "none",
    campaignTitle: campaigns.find((c) => c.id === campaignId)?.titleEn,
  };

  function submit() {
    setError(undefined);
    if (placement === "line:blood" && !health) {
      setError("The blood page only takes Health sponsors (hospitals, NGOs). Choose another page or another sponsor.");
      return;
    }
    startTransition(async () => {
      const res = await savePromo(
        promo?.id ?? null,
        {
          sponsorId,
          kind,
          placement,
          campaignId: kind === "campaign" ? campaignId || null : null,
          titleEn,
          titleBn,
          bodyEn,
          bodyBn,
          ctaEn,
          ctaBn,
          linkKind,
          link,
          code: code.trim(),
          expiresAt: expiresAt ? fromDhakaInput(expiresAt) || "invalid" : null,
          termsEn,
          termsBn,
          universityIds: everyone ? null : uniIds.length ? uniIds : cities.length ? null : [],
          cities: everyone ? null : cities.length ? cities : uniIds.length ? null : [],
          startsAt: fromDhakaInput(startsAt),
          endsAt: fromDhakaInput(endsAt),
          dailyCap: numberOrNaN(dailyCap),
          totalViews: totalViews.trim() === "" ? null : Number(totalViews),
          priority: numberOrNaN(priority),
        },
        live,
      );
      if (!res.ok) {
        setError(res.error);
        return;
      }
      if (!promo) {
        toast.success(needs.image === "required" ? "Draft created. Now add the image." : "Draft created");
        router.push(`/admin/ads/${res.data?.id}/edit`);
      } else {
        toast.success("Ad saved");
        router.push(`/admin/ads/${promo.id}`);
      }
      router.refresh();
    });
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_380px] lg:items-start">
      <div className="min-w-0 space-y-6">
        {/* On a phone the preview is at the end; this jumps to it. */}
        <a href="#ad-preview" className="inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline lg:hidden">
          <Megaphone className="size-4" aria-hidden /> See the preview
        </a>
        {live ? (
          <Note>This ad is live. Only the end, total views, times a day and priority can change. Pause it to change the rest.</Note>
        ) : ended ? (
          <Note>This ad has ended and can&apos;t change. Duplicate it to run it again.</Note>
        ) : null}

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Sponsor and kind</CardTitle>
            <CardDescription>Who pays for it, and where students see it.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <div className="space-y-2 sm:w-96">
              <Label htmlFor="ad-sponsor">Sponsor</Label>
              {sponsors.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  No sponsors yet.{" "}
                  <Link href="/admin/sponsors/new" className="text-primary hover:underline">
                    Add a sponsor
                  </Link>{" "}
                  first.
                </p>
              ) : (
                <Select value={sponsorId} onValueChange={setSponsorId} disabled={locked}>
                  <SelectTrigger id="ad-sponsor" className="w-full">
                    <SelectValue placeholder="Choose a sponsor" />
                  </SelectTrigger>
                  <SelectContent>
                    {sponsors.map((s) => (
                      <SelectItem key={s.id} value={s.id}>
                        {s.name}
                        {s.category === "health" ? <span className="text-xs text-muted-foreground"> · {categoryLabel.health}</span> : null}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </div>

            <fieldset className="space-y-2" disabled={locked}>
              <legend className="mb-2 text-sm font-medium">Kind</legend>
              <div role="radiogroup" aria-label="Kind" className="grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
                {kindOrder.map((k) => {
                  const Icon = kindIcon[k];
                  const on = kind === k;
                  return (
                    <button
                      key={k}
                      type="button"
                      role="radio"
                      aria-checked={on}
                      disabled={locked}
                      onClick={() => changeKind(k)}
                      className={cn(
                        "flex gap-3 rounded-xl border p-3 text-left transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-60",
                        on ? "border-primary bg-primary-soft/60" : "hover:border-primary/40 hover:bg-muted/50",
                      )}
                    >
                      <span
                        className={cn(
                          "inline-flex size-9 shrink-0 items-center justify-center rounded-lg",
                          on ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground",
                        )}
                      >
                        <Icon className="size-4" />
                      </span>
                      <span className="min-w-0">
                        <span className="block text-sm font-medium">{kindInfo[k].label}</span>
                        <span className="mt-0.5 block text-xs text-muted-foreground">{kindInfo[k].hint}</span>
                      </span>
                    </button>
                  );
                })}
              </div>
            </fieldset>

            {kind === "line" ? (
              <div className="space-y-2 sm:w-96">
                <Label htmlFor="ad-placement">Page</Label>
                <Select value={placement} onValueChange={(v) => setPlacement(v as PromoPlacement)} disabled={locked}>
                  <SelectTrigger id="ad-placement" className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {placementsFor.line.map((p) => (
                      <SelectItem key={p} value={p} disabled={p === "line:blood" && !health}>
                        {placementLabel[p]}
                        {p === "line:blood" && !health ? " (Health sponsors only)" : ""}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  At the bottom of the page. The blood page takes only Health sponsors (hospitals, NGOs), and never shows on a blood request.
                </p>
              </div>
            ) : null}

            {kind === "campaign" ? (
              <div className="space-y-2 sm:w-96">
                <Label htmlFor="ad-campaign">Campaign</Label>
                {campaigns.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No campaigns to sponsor yet.</p>
                ) : (
                  <Select value={campaignId} onValueChange={setCampaignId} disabled={locked}>
                    <SelectTrigger id="ad-campaign" className="w-full">
                      <SelectValue placeholder="Choose a campaign" />
                    </SelectTrigger>
                    <SelectContent>
                      {campaigns.map((c) => (
                        <SelectItem key={c.id} value={c.id}>
                          {c.titleEn} <span className="text-xs text-muted-foreground">· {c.status}</span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
                <p className="text-xs text-muted-foreground">One live sponsor per campaign. It uses the sponsor&apos;s name and logo.</p>
              </div>
            ) : null}
          </CardContent>
        </Card>

        {needs.texts || kind === "line" ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{kind === "line" ? "Lead text (optional)" : "What students read"}</CardTitle>
              <CardDescription>
                {kind === "line"
                  ? "Replaces “Supported by” before the logo, e.g. “Bus live, supported by”. Keep it short. Empty: “Supported by”."
                  : "Short and clear. English and Bangla; an empty Bangla field shows the English."}
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 sm:grid-cols-2">
              <Counted label={kind === "line" ? "Lead (English)" : "Title (English)"} id="ad-title-en" value={titleEn} max={limits.title} onChange={setTitleEn} disabled={locked} required={needs.texts} />
              <Counted label={kind === "line" ? "Lead (Bangla)" : "Title (Bangla)"} id="ad-title-bn" lang="bn" value={titleBn} max={limits.title} onChange={setTitleBn} disabled={locked} />
              {needs.texts ? (
                <>
                  <Counted label="Text (English)" id="ad-body-en" value={bodyEn} max={limits.body} onChange={setBodyEn} disabled={locked} multiline />
                  <Counted label="Text (Bangla)" id="ad-body-bn" lang="bn" value={bodyBn} max={limits.body} onChange={setBodyBn} disabled={locked} multiline />
                </>
              ) : null}
              {needs.cta ? (
                <>
                  <Counted label="Button (English)" id="ad-cta-en" value={ctaEn} max={limits.cta} onChange={setCtaEn} disabled={locked} placeholder="e.g. Get offer" />
                  <Counted label="Button (Bangla)" id="ad-cta-bn" lang="bn" value={ctaBn} max={limits.cta} onChange={setCtaBn} disabled={locked} placeholder="যেমন অফার নাও" />
                  <p className="text-xs text-muted-foreground sm:col-span-2">The button shows only when the ad has a link.</p>
                </>
              ) : null}
            </CardContent>
          </Card>
        ) : null}

        {needs.image !== "none" ? (
          promo ? (
            <ImageUploadField
              title="Image"
              required={needs.image === "required"}
              description={
                needs.image === "required"
                  ? "Required. 2:1, e.g. 1600×800 (JPEG, PNG or WebP, up to 8 MB). Keep words and logos away from the edges: small phones crop a little."
                  : "Optional: a square photo for the deal, shown small beside it (up to 8 MB). Without one, the sponsor's logo is shown."
              }
              uploadUrl={`/admin/promo-image/${promo.id}`}
              url={promo.imageUrl}
              shape={needs.image === "required" ? "wide" : "square"}
              maxMb={8}
              side={1600}
              format="jpeg"
              onRemove={() => removePromoImage(promo.id)}
              disabled={locked}
            />
          ) : (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Image</CardTitle>
                <CardDescription>
                  {needs.image === "required" ? "Required, 2:1 (e.g. 1600×800)." : "Optional."} You can add it right after the draft is created.
                </CardDescription>
              </CardHeader>
            </Card>
          )
        ) : null}

        {needs.deal ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-base">The deal</CardTitle>
              <CardDescription>Students copy the code with one tap. Expired deals disappear by themselves.</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 sm:grid-cols-2">
              <Counted label="Promo code (optional)" id="ad-code" value={code} max={limits.code} onChange={(v) => setCode(v.toUpperCase().replace(/\s+/g, ""))} disabled={locked} placeholder="e.g. VK20" mono />
              <div className="space-y-2">
                <Label htmlFor="ad-expires">Valid till (Bangladesh time, optional)</Label>
                <Input id="ad-expires" type="datetime-local" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} disabled={locked} />
              </div>
              <Counted label="Terms (English, optional)" id="ad-terms-en" value={termsEn} max={limits.terms} onChange={setTermsEn} disabled={locked} multiline />
              <Counted label="Terms (Bangla, optional)" id="ad-terms-bn" lang="bn" value={termsBn} max={limits.terms} onChange={setTermsBn} disabled={locked} multiline />
            </CardContent>
          </Card>
        ) : null}

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Link</CardTitle>
            <CardDescription>What a tap opens. Websites open in the in-app browser.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div role="radiogroup" aria-label="Link" className="flex flex-wrap gap-4 text-sm">
              {(
                [
                  ["none", "No link"],
                  ["web", "A website"],
                  ["app", "A screen in the app"],
                ] as const
              ).map(([v, l]) => (
                <label key={v} className="flex items-center gap-2">
                  <input type="radio" name="ad-link" checked={linkKind === v} onChange={() => setLinkKind(v)} disabled={locked} /> {l}
                </label>
              ))}
            </div>
            {linkKind === "web" ? (
              <div className="space-y-2">
                <Label htmlFor="ad-web">Website</Label>
                <Input
                  id="ad-web"
                  type="url"
                  inputMode="url"
                  placeholder="https://"
                  value={webLink}
                  maxLength={limits.link}
                  onChange={(e) => setWebLink(e.target.value)}
                  disabled={locked}
                  aria-invalid={webLink !== "" && !/^https:\/\//i.test(webLink)}
                />
                {webLink !== "" && !/^https:\/\//i.test(webLink) ? (
                  <p className="text-xs text-destructive">Use a secure link that starts with https://</p>
                ) : null}
              </div>
            ) : null}
            {linkKind === "app" ? (
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="ad-route">Screen</Label>
                  <Select value={appRoute} onValueChange={setAppRoute} disabled={locked}>
                    <SelectTrigger id="ad-route" className="w-full">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {appRoutes.map((r) => (
                        <SelectItem key={r.value} value={r.value}>
                          {r.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                {appRoute === CAMPAIGN_PLACEHOLDER ? (
                  <div className="space-y-2">
                    <Label htmlFor="ad-route-campaign">Campaign</Label>
                    <Select value={linkCampaignId} onValueChange={setLinkCampaignId} disabled={locked}>
                      <SelectTrigger id="ad-route-campaign" className="w-full">
                        <SelectValue placeholder="Choose a campaign" />
                      </SelectTrigger>
                      <SelectContent>
                        {campaigns.map((c) => (
                          <SelectItem key={c.id} value={c.id}>
                            {c.titleEn}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                ) : null}
              </div>
            ) : null}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Who sees it</CardTitle>
            <CardDescription>Everyone, or students at some universities or in some cities.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div role="radiogroup" aria-label="Who sees it" className="flex flex-wrap gap-4 text-sm">
              <label className="flex items-center gap-2">
                <input type="radio" name="ad-scope" checked={everyone} onChange={() => setEveryone(true)} disabled={locked} /> All students
              </label>
              <label className="flex items-center gap-2">
                <input type="radio" name="ad-scope" checked={!everyone} onChange={() => setEveryone(false)} disabled={locked} /> Only some
              </label>
            </div>
            {!everyone ? (
              <div className="space-y-5">
                <div className="space-y-2">
                  <Label>Universities</Label>
                  {!locked ? (
                    <div className="sm:w-96">
                      <UniversityCombobox
                        universities={universities.filter((u) => !uniIds.includes(u.id))}
                        value={null}
                        onChange={(id) => id && setUniIds((l) => [...l, id])}
                        placeholder="Add a university"
                      />
                    </div>
                  ) : null}
                  <Chips
                    items={uniIds.map((id) => ({ key: id, label: unis.get(id) ?? id }))}
                    empty="Any university"
                    onRemove={locked ? undefined : (id) => setUniIds((l) => l.filter((x) => x !== id))}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="ad-city">Cities</Label>
                  {!locked ? (
                    <div className="sm:w-96">
                      <Select value="" onValueChange={(c) => c && setCities((l) => (l.includes(c) ? l : [...l, c]))}>
                        <SelectTrigger id="ad-city" className="w-full">
                          <SelectValue placeholder={allCities.length ? "Add a city" : "No cities in the university list"} />
                        </SelectTrigger>
                        <SelectContent>
                          {allCities
                            .filter((c) => !cities.includes(c))
                            .map((c) => (
                              <SelectItem key={c} value={c}>
                                {c}
                              </SelectItem>
                            ))}
                        </SelectContent>
                      </Select>
                    </div>
                  ) : null}
                  <Chips
                    items={cities.map((c) => ({ key: c, label: c }))}
                    empty="Any city"
                    onRemove={locked ? undefined : (c) => setCities((l) => l.filter((x) => x !== c))}
                  />
                </div>
                <p className="flex items-start gap-2 text-xs text-muted-foreground">
                  <Info className="mt-0.5 size-3.5 shrink-0" aria-hidden />
                  With both, a student must match both: one of the universities, in one of the cities. A city is the university&apos;s city.
                </p>
              </div>
            ) : null}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Schedule and delivery</CardTitle>
            <CardDescription>Bangladesh time. The ad stops by itself at the end, or when it reaches its total views.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="ad-start">Starts</Label>
              <Input id="ad-start" type="datetime-local" value={startsAt} onChange={(e) => setStartsAt(e.target.value)} disabled={locked} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="ad-end">Ends</Label>
              <Input id="ad-end" type="datetime-local" value={endsAt} onChange={(e) => setEndsAt(e.target.value)} disabled={ended} />
            </div>
            {needs.dailyCap ? (
              <div className="space-y-2">
                <Label htmlFor="ad-cap">Times a day, per student</Label>
                <Input id="ad-cap" type="number" inputMode="numeric" min={1} max={20} step={1} value={dailyCap} onChange={(e) => setDailyCap(e.target.value)} disabled={ended} />
                <p className="text-xs text-muted-foreground">1–20. Keep it low (1–2) so students don&apos;t tire of it.</p>
              </div>
            ) : null}
            <div className="space-y-2">
              <Label htmlFor="ad-total">Total views (optional)</Label>
              <Input
                id="ad-total"
                type="number"
                inputMode="numeric"
                min={1}
                step={1}
                placeholder="No limit"
                value={totalViews}
                onChange={(e) => setTotalViews(e.target.value)}
                disabled={ended}
              />
              <p className="text-xs text-muted-foreground">What the sponsor paid for. Empty: no limit.</p>
            </div>
            <div className="space-y-2 sm:col-span-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="ad-priority">Priority</Label>
                <span className="text-sm font-medium tabular-nums">{priority}/10</span>
              </div>
              <input
                id="ad-priority"
                type="range"
                min={1}
                max={10}
                step={1}
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
                disabled={ended}
                className="w-full accent-[var(--primary)] sm:w-96"
              />
              <p className="text-xs text-muted-foreground">When several ads fit the same place, higher priority shows more often.</p>
            </div>
          </CardContent>
        </Card>

        {error ? (
          <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error}
          </p>
        ) : null}
        <div className="flex gap-2">
          <Button onClick={submit} disabled={pending || ended || !sponsorId}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            {promo ? "Save" : "Create draft"}
          </Button>
          <Button variant="outline" onClick={() => router.back()} disabled={pending}>
            Cancel
          </Button>
        </div>
      </div>

      <aside id="ad-preview" className="scroll-mt-20 lg:sticky lg:top-20">
        <Card>
          <CardContent>
            <PromoPreview data={preview} />
            <p className="mt-3 flex items-center gap-1.5 text-xs text-muted-foreground">
              <Megaphone className="size-3.5" aria-hidden /> {kindInfo[kind].label} · {placementLabel[placement]}
            </p>
          </CardContent>
        </Card>
      </aside>
    </div>
  );
}

function Note({ children }: { children: React.ReactNode }) {
  return <p className="rounded-lg border bg-muted/40 px-3 py-2 text-sm text-muted-foreground">{children}</p>;
}

/** A text field with a live "12/60" counter that warns near the limit. */
function Counted({
  label,
  id,
  value,
  max,
  onChange,
  disabled,
  multiline,
  lang,
  placeholder,
  required,
  mono,
}: {
  label: string;
  id: string;
  value: string;
  max: number;
  onChange: (v: string) => void;
  disabled?: boolean;
  multiline?: boolean;
  lang?: string;
  placeholder?: string;
  required?: boolean;
  mono?: boolean;
}) {
  const n = [...value].length;
  const tone = n >= max ? "text-destructive" : n >= max * 0.9 ? "text-warning" : "text-muted-foreground";
  const props = {
    id,
    lang,
    value,
    maxLength: max,
    placeholder,
    disabled,
    "aria-describedby": `${id}-count`,
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => onChange(e.target.value),
  };
  return (
    <div className="space-y-2">
      <div className="flex items-baseline justify-between gap-2">
        <Label htmlFor={id}>
          {label}
          {required ? <span className="text-destructive"> *</span> : null}
        </Label>
        <span id={`${id}-count`} className={cn("text-xs tabular-nums", tone)} aria-live="polite">
          {n}/{max}
        </span>
      </div>
      {multiline ? <Textarea rows={3} {...props} /> : <Input {...props} className={mono ? "font-mono tracking-wider" : undefined} />}
    </div>
  );
}

function Chips({ items, empty, onRemove }: { items: { key: string; label: string }[]; empty: string; onRemove?: (key: string) => void }) {
  return (
    <ul className="flex flex-wrap gap-2">
      {items.length === 0 ? <li className="text-sm text-muted-foreground">{empty}</li> : null}
      {items.map((i) => (
        <li key={i.key} className="flex items-center gap-1 rounded-full border bg-card py-1 ps-3 pe-1 text-sm">
          {i.label}
          {onRemove ? (
            <Button variant="ghost" size="icon" className="size-6" aria-label={`Remove ${i.label}`} onClick={() => onRemove(i.key)}>
              <X />
            </Button>
          ) : (
            <span className="pe-2" />
          )}
        </li>
      ))}
    </ul>
  );
}
