"use client";

import { Bell, Check, ChevronsUpDown, Loader2, Send, Users } from "lucide-react";
import { useEffect, useState, useTransition } from "react";
import { toast } from "sonner";

import { searchUsers } from "@/app/admin/(panel)/users/actions";
import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";

import { sendPush } from "./actions";

type Picked = { id: string; email: string; displayName: string | null };

export function PushForm({ initialUser }: { initialUser?: Picked }) {
  const [target, setTarget] = useState<"user" | "all">("user");
  const [user, setUser] = useState<Picked | undefined>(initialUser);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [titleBn, setTitleBn] = useState("");
  const [bodyBn, setBodyBn] = useState("");
  const [lang, setLang] = useState<"en" | "bn">("en");
  const [pending, startTransition] = useTransition();

  const ready = title.trim() && body.trim() && (target === "all" || user);
  const input = { target, userId: user?.id, title, body, titleBn, bodyBn };

  function sendToUser() {
    startTransition(async () => {
      const res = await sendPush(input);
      if (res.ok) toast.success(res.message ?? "Sent");
      else toast.error(res.error);
    });
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_22rem]">
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Message</CardTitle>
          <CardDescription>Phones in Bangla get the Bangla text when you write one, English otherwise.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="space-y-2">
            <Label>Send to</Label>
            <Tabs value={target} onValueChange={(v) => setTarget(v as "user" | "all")}>
              <TabsList>
                <TabsTrigger value="user">One person</TabsTrigger>
                <TabsTrigger value="all">
                  <Users /> Everyone
                </TabsTrigger>
              </TabsList>
            </Tabs>
            {target === "user" ? (
              <UserPicker value={user} onChange={setUser} />
            ) : (
              <p className="rounded-md bg-warning-soft px-3 py-2 text-sm text-warning">
                Goes to every user with a phone registered for push. Use it rarely.
              </p>
            )}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <fieldset className="space-y-3">
              <legend className="mb-2 text-sm font-medium">English</legend>
              <div className="space-y-1.5">
                <Label htmlFor="title">Title</Label>
                <Input id="title" value={title} maxLength={80} onChange={(e) => setTitle(e.target.value)} required />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="body">Message</Label>
                <Textarea id="body" value={body} maxLength={240} rows={4} onChange={(e) => setBody(e.target.value)} required />
                <p className="text-end text-xs text-muted-foreground tabular-nums">{body.length}/240</p>
              </div>
            </fieldset>
            <fieldset className="space-y-3" lang="bn">
              <legend className="mb-2 text-sm font-medium">
                বাংলা <span className="font-normal text-muted-foreground">(optional)</span>
              </legend>
              <div className="space-y-1.5">
                <Label htmlFor="titleBn">শিরোনাম</Label>
                <Input id="titleBn" value={titleBn} maxLength={80} onChange={(e) => setTitleBn(e.target.value)} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="bodyBn">বার্তা</Label>
                <Textarea id="bodyBn" value={bodyBn} maxLength={240} rows={4} onChange={(e) => setBodyBn(e.target.value)} />
                <p className="text-end text-xs text-muted-foreground tabular-nums">{bodyBn.length}/240</p>
              </div>
            </fieldset>
          </div>

          <div className="flex justify-end">
            {target === "all" ? (
              <ConfirmAction
                trigger={
                  <Button disabled={!ready || pending}>
                    <Send /> Send to everyone
                  </Button>
                }
                title="Send this push to everyone?"
                description={
                  <>
                    <p>
                      <strong>{title}</strong> — {body}
                    </p>
                    <p>Every user with a phone registered for push gets it. It can&apos;t be taken back.</p>
                  </>
                }
                confirmLabel="Send to everyone"
                typeToConfirm="everyone"
                action={() => sendPush(input)}
                success="Sent"
              />
            ) : (
              <Button disabled={!ready || pending} onClick={sendToUser}>
                {pending ? <Loader2 className="animate-spin" /> : <Send />}
                Send
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium">Preview</p>
          <Tabs value={lang} onValueChange={(v) => setLang(v as "en" | "bn")}>
            <TabsList className="h-8">
              <TabsTrigger value="en" className="text-xs">
                English
              </TabsTrigger>
              <TabsTrigger value="bn" className="text-xs">
                বাংলা
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>
        <Preview
          title={(lang === "bn" && titleBn.trim()) || title}
          body={(lang === "bn" && bodyBn.trim()) || body}
        />
      </div>
    </div>
  );
}

function Preview({ title, body }: { title: string; body: string }) {
  return (
    <div aria-label="Notification preview" className="rounded-3xl bg-slate-900 p-4 text-slate-100 shadow-inner">
      <div className="rounded-2xl bg-slate-800 p-3.5">
        <div className="flex items-center gap-2 text-xs text-slate-400">
          <span className="inline-flex size-5 items-center justify-center rounded-full bg-teal-700">
            <Bell className="size-3 text-white" />
          </span>
          VarsityKotha · now
        </div>
        <p className="mt-2 text-sm font-semibold">{title || "Title"}</p>
        <p className="mt-0.5 text-sm whitespace-pre-line text-slate-300">{body || "Your message appears here."}</p>
      </div>
    </div>
  );
}

function UserPicker({ value, onChange }: { value?: Picked; onChange: (u: Picked) => void }) {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [results, setResults] = useState<Picked[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const term = q.trim();
    if (term.length < 2) return;
    let live = true;
    const t = setTimeout(async () => {
      setLoading(true);
      const res = await searchUsers(term);
      if (!live) return;
      setLoading(false);
      if (res.ok) setResults(res.data ?? []);
      else toast.error(res.error);
    }, 250);
    return () => {
      live = false;
      clearTimeout(t);
    };
  }, [q]);

  const shown = q.trim().length < 2 ? [] : results;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="outline" role="combobox" aria-expanded={open} className="w-full justify-between font-normal sm:w-96">
          <span className={cn("truncate", !value && "text-muted-foreground")}>
            {value ? `${value.displayName || value.email} · ${value.email}` : "Find a user by email or name"}
          </span>
          <ChevronsUpDown className="opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-(--radix-popover-trigger-width) min-w-80 p-0" align="start">
        <Command shouldFilter={false}>
          <CommandInput placeholder="Type at least 2 letters…" value={q} onValueChange={setQ} />
          <CommandList>
            {loading ? (
              <div className="flex items-center justify-center py-6 text-sm text-muted-foreground">
                <Loader2 className="me-2 size-4 animate-spin" /> Searching…
              </div>
            ) : (
              <CommandEmpty>{q.trim().length < 2 ? "Type an email or name." : "No user found."}</CommandEmpty>
            )}
            <CommandGroup>
              {shown.map((u) => (
                <CommandItem
                  key={u.id}
                  value={u.id}
                  onSelect={() => {
                    onChange(u);
                    setOpen(false);
                  }}
                >
                  <Check className={cn("size-4", value?.id === u.id ? "opacity-100" : "opacity-0")} />
                  <span className="min-w-0">
                    <span className="block truncate">{u.displayName || "No name yet"}</span>
                    <span className="block truncate text-xs text-muted-foreground">{u.email}</span>
                  </span>
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
