"use client";

import { Loader2, Plus, Trash2, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  type AdminCampaign,
  type CampaignScoring,
  fromDhakaInput,
  type ScoringKey,
  scoringRange,
  toDhakaInput,
  withDefaults,
} from "@/lib/admin/growth";

import { saveCampaign } from "./actions";
import { BannerField } from "./banner-field";

type PrizeRow = { rankFrom: string; rankTo: string; titleEn: string; titleBn: string };

/** The points fields, grouped as on the rules page; `hint` says what earns it. */
const pointFields: { title: string; fields: { key: ScoringKey; label: string; hint: string }[] }[] = [
  {
    title: "Invites",
    fields: [
      { key: "invite", label: "Per friend", hint: "Verified and active on 3 days within 14 days." },
      { key: "otherCampus", label: "Extra: other university", hint: "The friend is at a different university." },
      { key: "pioneer", label: "Extra: pioneer friend", hint: "The friend is among the first students of their university." },
      { key: "pioneerFirst", label: "Pioneer: first how many", hint: "Verified students of that university, counted in order." },
      { key: "friendSection", label: "Extra: friend in a section", hint: "The friend joins a class section." },
    ],
  },
  {
    title: "Missions",
    fields: [
      { key: "joinSection", label: "Joined a section", hint: "Once." },
      { key: "bloodDonor", label: "Blood donor", hint: "Once, when registered as a donor." },
      { key: "busShare", label: "Live bus, per day", hint: "10+ minutes, and another student watched." },
      { key: "busShareDays", label: "Live bus: most days", hint: "Days that count in the campaign." },
      { key: "sectionSetup", label: "Section set up, as CR", hint: "5+ classes in the routine and 5+ verified members." },
      { key: "sectionSetupMax", label: "Sections: most that count", hint: "Per CR." },
    ],
  },
];

function scoringText(s: CampaignScoring): Record<ScoringKey, string> {
  return Object.fromEntries(Object.entries(s).map(([k, v]) => [k, String(v)])) as Record<ScoringKey, string>;
}

const DAY = 24 * 3600_000;

/** Adds a day offset to a Bangladesh-time input value. */
function shift(v: string, ms: number): string {
  const iso = fromDhakaInput(v);
  return iso ? toDhakaInput(new Date(Date.parse(iso) + ms).toISOString()) : "";
}

/**
 * Create or edit a campaign. Once it is live only the end and settle dates,
 * the rules and the prizes can change, so the other fields are locked.
 */
export function CampaignForm({ campaign, universities }: { campaign?: AdminCampaign; universities: UniversityOption[] }) {
  const router = useRouter();
  const live = Boolean(campaign && campaign.status !== "draft");
  const [titleEn, setTitleEn] = useState(campaign?.titleEn ?? "");
  const [titleBn, setTitleBn] = useState(campaign?.titleBn ?? "");
  const [bodyEn, setBodyEn] = useState(campaign?.bodyEn ?? "");
  const [bodyBn, setBodyBn] = useState(campaign?.bodyBn ?? "");
  const [rulesEn, setRulesEn] = useState(campaign?.rulesEn ?? "");
  const [rulesBn, setRulesBn] = useState(campaign?.rulesBn ?? "");
  const [startsAt, setStartsAt] = useState(campaign ? toDhakaInput(campaign.startsAt) : "");
  const [endsAt, setEndsAt] = useState(campaign ? toDhakaInput(campaign.endsAt) : "");
  const [settlesAt, setSettlesAt] = useState(campaign ? toDhakaInput(campaign.settlesAt) : "");
  const [settleTouched, setSettleTouched] = useState(Boolean(campaign));
  const [all, setAll] = useState(campaign ? campaign.universityIds === null : true);
  const [uniIds, setUniIds] = useState<string[]>(campaign?.universityIds ?? []);
  const [prizes, setPrizes] = useState<PrizeRow[]>(
    campaign?.prizes?.length
      ? campaign.prizes.map((p) => ({ rankFrom: String(p.rankFrom), rankTo: String(p.rankTo), titleEn: p.titleEn, titleBn: p.titleBn }))
      : [{ rankFrom: "1", rankTo: "1", titleEn: "", titleBn: "" }],
  );
  const [scoring, setScoring] = useState<Record<ScoringKey, string>>(() => scoringText(withDefaults(campaign?.scoring)));
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function changeEnd(v: string) {
    setEndsAt(v);
    if (!settleTouched) setSettlesAt(shift(v, 7 * DAY));
  }

  function setPrize(i: number, change: Partial<PrizeRow>) {
    setPrizes((ps) => ps.map((p, j) => (j === i ? { ...p, ...change } : p)));
  }

  function submit() {
    setError(undefined);
    startTransition(async () => {
      const res = await saveCampaign(
        campaign?.id ?? null,
        {
          titleEn,
          titleBn,
          bodyEn,
          bodyBn,
          rulesEn,
          rulesBn,
          startsAt: fromDhakaInput(startsAt),
          endsAt: fromDhakaInput(endsAt),
          settlesAt: fromDhakaInput(settlesAt),
          universityIds: all ? null : uniIds,
          prizes: prizes.map((p) => ({ rankFrom: Number(p.rankFrom), rankTo: Number(p.rankTo), titleEn: p.titleEn, titleBn: p.titleBn })),
          // An empty field is NaN, which the check below refuses.
          scoring: Object.fromEntries(Object.entries(scoring).map(([k, v]) => [k, v.trim() === "" ? Number.NaN : Number(v)])) as CampaignScoring,
        },
        live,
      );
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success(campaign ? "Campaign saved" : "Draft created");
      router.push(`/admin/campaigns/${res.data?.id ?? campaign?.id ?? ""}`);
      router.refresh();
    });
  }

  const unis = new Map(universities.map((u) => [u.id, u.name]));

  return (
    <div className="max-w-3xl space-y-6">
      {live ? (
        <p className="rounded-lg border bg-muted/40 px-3 py-2 text-sm text-muted-foreground">
          This campaign is live. Only the end and settle dates, the rules and the prizes can change.
        </p>
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">What students see</CardTitle>
          <CardDescription>English and Bangla. The app shows the student&apos;s language.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2">
          <Field label="Title (English)" htmlFor="c-title-en">
            <Input id="c-title-en" value={titleEn} onChange={(e) => setTitleEn(e.target.value)} maxLength={120} disabled={live} />
          </Field>
          <Field label="Title (Bangla)" htmlFor="c-title-bn">
            <Input id="c-title-bn" lang="bn" value={titleBn} onChange={(e) => setTitleBn(e.target.value)} maxLength={120} disabled={live} />
          </Field>
          <Field label="Description (English)" htmlFor="c-body-en">
            <Textarea id="c-body-en" rows={4} value={bodyEn} onChange={(e) => setBodyEn(e.target.value)} maxLength={2000} disabled={live} />
          </Field>
          <Field label="Description (Bangla)" htmlFor="c-body-bn">
            <Textarea id="c-body-bn" lang="bn" rows={4} value={bodyBn} onChange={(e) => setBodyBn(e.target.value)} maxLength={2000} disabled={live} />
          </Field>
          <Field label={`Rules (English) · ${rulesEn.length}/8000`} htmlFor="c-rules-en">
            <Textarea id="c-rules-en" rows={8} value={rulesEn} onChange={(e) => setRulesEn(e.target.value)} maxLength={8000} />
          </Field>
          <Field label={`Rules (Bangla) · ${rulesBn.length}/8000`} htmlFor="c-rules-bn">
            <Textarea id="c-rules-bn" lang="bn" rows={8} value={rulesBn} onChange={(e) => setRulesBn(e.target.value)} maxLength={8000} />
          </Field>
          <p className="text-xs text-muted-foreground sm:col-span-2">
            Rules appear on the public rules page as plain text with your line breaks. The fixed sections (how to take part, how to earn points, who
            can take part, winners, Google) are added around them.
          </p>
        </CardContent>
      </Card>

      {campaign ? (
        <BannerField campaignId={campaign.id} bannerUrl={campaign.bannerUrl} />
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Banner</CardTitle>
            <CardDescription>A photo for the campaign, 2:1, e.g. 1600×800. You can add it once the draft is created.</CardDescription>
          </CardHeader>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Dates</CardTitle>
          <CardDescription>Bangladesh time. Settle is when invites must have qualified by, and the earliest you can announce winners.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-3">
          <Field label="Starts" htmlFor="c-start">
            <Input id="c-start" type="datetime-local" value={startsAt} onChange={(e) => setStartsAt(e.target.value)} disabled={live} />
          </Field>
          <Field label="Ends" htmlFor="c-end">
            <Input id="c-end" type="datetime-local" value={endsAt} onChange={(e) => changeEnd(e.target.value)} />
          </Field>
          <Field label="Settles (default: end + 7 days)" htmlFor="c-settle">
            <Input
              id="c-settle"
              type="datetime-local"
              value={settlesAt}
              onChange={(e) => {
                setSettleTouched(true);
                setSettlesAt(e.target.value);
              }}
            />
          </Field>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Universities</CardTitle>
          <CardDescription>Which students can take part.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex gap-4 text-sm">
            <label className="flex items-center gap-2">
              <input type="radio" name="scope" checked={all} onChange={() => setAll(true)} disabled={live} /> All universities
            </label>
            <label className="flex items-center gap-2">
              <input type="radio" name="scope" checked={!all} onChange={() => setAll(false)} disabled={live} /> Only some
            </label>
          </div>
          {!all ? (
            <>
              {!live ? (
                <div className="sm:w-96">
                  <UniversityCombobox
                    universities={universities.filter((u) => !uniIds.includes(u.id))}
                    value={null}
                    onChange={(id) => id && setUniIds((l) => [...l, id])}
                    placeholder="Add a university"
                  />
                </div>
              ) : null}
              <ul className="flex flex-wrap gap-2">
                {uniIds.length === 0 ? <li className="text-sm text-muted-foreground">No university chosen yet.</li> : null}
                {uniIds.map((id) => (
                  <li key={id} className="flex items-center gap-1 rounded-full border bg-card py-1 ps-3 pe-1 text-sm">
                    {unis.get(id) ?? id}
                    {!live ? (
                      <Button variant="ghost" size="icon" className="size-6" aria-label={`Remove ${unis.get(id) ?? "university"}`} onClick={() => setUniIds((l) => l.filter((x) => x !== id))}>
                        <X />
                      </Button>
                    ) : null}
                  </li>
                ))}
              </ul>
            </>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Points</CardTitle>
          <CardDescription>
            What each thing is worth. 0 turns it off. The rules page lists them for students. Points can only change while the campaign is a draft.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          {pointFields.map((g) => (
            <fieldset key={g.title} className="space-y-3">
              <legend className="text-sm font-medium text-muted-foreground">{g.title}</legend>
              <div className="grid gap-4 sm:grid-cols-3">
                {g.fields.map((f) => {
                  const r = scoringRange[f.key];
                  const id = `s-${f.key}`;
                  return (
                    <div key={f.key} className="space-y-1.5">
                      <Label htmlFor={id}>{f.label}</Label>
                      <Input
                        id={id}
                        type="number"
                        inputMode="numeric"
                        min={r.min}
                        max={r.max}
                        step={1}
                        value={scoring[f.key]}
                        onChange={(e) => setScoring((s) => ({ ...s, [f.key]: e.target.value }))}
                        disabled={live}
                        aria-describedby={`${id}-hint`}
                      />
                      <p id={`${id}-hint`} className="text-xs text-muted-foreground">
                        {f.hint} {r.min}–{r.max}.
                      </p>
                    </div>
                  );
                })}
              </div>
            </fieldset>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Prizes</CardTitle>
          <CardDescription>By rank. One row can cover several ranks (for example 4 to 10). No lucky draws, and never for ratings or reviews.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {prizes.map((p, i) => (
            <div key={i} className="grid gap-2 rounded-lg border p-3 sm:grid-cols-[5rem_5rem_1fr_1fr_auto] sm:items-end">
              <Field label="Rank from" htmlFor={`p-from-${i}`}>
                <Input id={`p-from-${i}`} type="number" min={1} value={p.rankFrom} onChange={(e) => setPrize(i, { rankFrom: e.target.value })} />
              </Field>
              <Field label="Rank to" htmlFor={`p-to-${i}`}>
                <Input id={`p-to-${i}`} type="number" min={1} value={p.rankTo} onChange={(e) => setPrize(i, { rankTo: e.target.value })} />
              </Field>
              <Field label="Prize (English)" htmlFor={`p-en-${i}`}>
                <Input id={`p-en-${i}`} value={p.titleEn} maxLength={120} placeholder="e.g. Smartphone" onChange={(e) => setPrize(i, { titleEn: e.target.value })} />
              </Field>
              <Field label="Prize (Bangla)" htmlFor={`p-bn-${i}`}>
                <Input id={`p-bn-${i}`} lang="bn" value={p.titleBn} maxLength={120} onChange={(e) => setPrize(i, { titleBn: e.target.value })} />
              </Field>
              <Button variant="ghost" size="icon" aria-label="Remove prize" disabled={prizes.length === 1} onClick={() => setPrizes((ps) => ps.filter((_, j) => j !== i))}>
                <Trash2 />
              </Button>
            </div>
          ))}
          <Button
            variant="outline"
            onClick={() => {
              const last = Number(prizes[prizes.length - 1]?.rankTo) || 0;
              setPrizes((ps) => [...ps, { rankFrom: String(last + 1), rankTo: String(last + 1), titleEn: "", titleBn: "" }]);
            }}
          >
            <Plus /> Add a prize
          </Button>
        </CardContent>
      </Card>

      {error ? (
        <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
      <div className="flex gap-2">
        <Button onClick={submit} disabled={pending}>
          {pending ? <Loader2 className="animate-spin" /> : null}
          {campaign ? "Save" : "Create draft"}
        </Button>
        <Button variant="outline" onClick={() => router.back()} disabled={pending}>
          Cancel
        </Button>
      </div>
    </div>
  );
}

function Field({ label, htmlFor, children }: { label: string; htmlFor: string; children: React.ReactNode }) {
  return (
    <div className="space-y-2">
      <Label htmlFor={htmlFor}>{label}</Label>
      {children}
    </div>
  );
}
