import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { load } from "@/lib/admin/load";
import { api } from "@/lib/admin/session";
import type { ConfigItem } from "@/lib/admin/types";
import { formatDateTime } from "@/lib/format";

import { FeatureFlags, JsonSetting, MinBuild } from "./settings-forms";

export const metadata = { title: "Settings" };

export default async function SettingsPage() {
  const res = await load(() => api<{ items: ConfigItem[] }>("/admin/config"));
  const items = res.data?.items ?? [];
  const byKey = new Map(items.map((i) => [i.key, i]));
  const features = byKey.get("features");
  const minBuild = byKey.get("minSupportedBuild");
  const others = items.filter((i) => i.key !== "features" && i.key !== "minSupportedBuild");

  return (
    <>
      <PageHeader title="App settings" description="Read by every phone when the app starts (GET /config)." />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Feature flags</CardTitle>
              <CardDescription>
                Turn whole features on or off.{" "}
                {features ? `Changed ${formatDateTime(features.updatedAt)}.` : ""}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <FeatureFlags features={(features?.value as Record<string, boolean>) ?? {}} />
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Forced update</CardTitle>
              <CardDescription>
                Phones on an older build must update before they can use the app.{" "}
                {minBuild ? `Changed ${formatDateTime(minBuild.updatedAt)}.` : ""}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <MinBuild value={typeof minBuild?.value === "number" ? minBuild.value : 1} />
            </CardContent>
          </Card>
          {others.length > 0 ? (
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base">Other settings</CardTitle>
                <CardDescription>Raw values (JSON). Check the app reads the shape you save.</CardDescription>
              </CardHeader>
              <CardContent className="grid gap-6 md:grid-cols-2">
                {others.map((i) => (
                  <JsonSetting key={i.key} k={i.key} value={i.value} />
                ))}
              </CardContent>
            </Card>
          ) : null}
        </div>
      )}
    </>
  );
}
