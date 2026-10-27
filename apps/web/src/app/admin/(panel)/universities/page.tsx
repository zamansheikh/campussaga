import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { query } from "@/lib/admin/session";
import { allUniversities } from "@/lib/admin/universities";
import { formatNumber } from "@/lib/format";

import { ActiveSwitch } from "./active-switch";
import { DomainsDialog, UniversityDialog } from "./university-dialog";

export const metadata = { title: "Universities" };

export default async function UniversitiesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; active?: string }>;
}) {
  const sp = await searchParams;
  const active = sp.active === "true" || sp.active === "false" ? sp.active : undefined;
  const res = await load(() => allUniversities(query({ q: sp.q, active })));
  return (
    <>
      <PageHeader
        title="Universities"
        description={
          res.data ? `${formatNumber(res.data.length)} shown. Students pick from active ones.` : "Universities students can pick."
        }
        actions={<UniversityDialog />}
      />
      <ListFilters
        searchPlaceholder="Name, slug or domain"
        selects={[
          {
            name: "active",
            label: "States",
            options: [
              { value: "true", label: "Active" },
              { value: "false", label: "Inactive" },
            ],
          },
        ]}
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.length === 0 ? (
        <EmptyState title="No universities found">
          Try a different search, or add it with &quot;Add university&quot;.
        </EmptyState>
      ) : res.data ? (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>University</TableHead>
                <TableHead className="hidden md:table-cell">Email domains</TableHead>
                <TableHead className="hidden text-end sm:table-cell">Students</TableHead>
                <TableHead className="hidden text-end lg:table-cell">Groups</TableHead>
                <TableHead>Active</TableHead>
                <TableHead className="w-10">
                  <span className="sr-only">Edit</span>
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {res.data.map((u) => (
                <TableRow key={u.id} className={u.active ? undefined : "opacity-60"}>
                  <TableCell className="max-w-80">
                    <p className="font-medium whitespace-normal">{u.name}</p>
                    <p className="text-xs whitespace-normal text-muted-foreground">
                      <span className="font-mono">{u.slug}</span>
                      {u.city ? ` · ${u.city}` : ""}
                      {u.kind ? ` · ${u.kind}` : ""}
                      {u.nameBn ? (
                        <span lang="bn" className="block">
                          {u.nameBn}
                        </span>
                      ) : null}
                    </p>
                    <span className="md:hidden">
                      <DomainsDialog university={u} />
                    </span>
                  </TableCell>
                  <TableCell className="hidden max-w-64 md:table-cell">
                    <div className="flex flex-wrap gap-1">
                      {u.domains.length === 0 ? (
                        <span className="text-xs text-muted-foreground">None</span>
                      ) : (
                        u.domains.map((d) => (
                          <Badge key={d} variant="secondary" className="font-mono text-xs">
                            {d}
                          </Badge>
                        ))
                      )}
                    </div>
                    <DomainsDialog university={u} />
                  </TableCell>
                  <TableCell className="hidden text-end tabular-nums sm:table-cell">
                    {formatNumber(u.users)}
                  </TableCell>
                  <TableCell className="hidden text-end tabular-nums lg:table-cell">
                    {formatNumber(u.groups)}
                  </TableCell>
                  <TableCell>
                    <ActiveSwitch id={u.id} name={u.name} active={u.active} />
                  </TableCell>
                  <TableCell>
                    <UniversityDialog university={u} />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : null}
    </>
  );
}
