"use client";

import { ArrowLeft, Loader2, Mail } from "lucide-react";
import { useActionState, useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { login, type LoginState } from "./actions";

export function LoginForm({ next, notice }: { next: string; notice?: string }) {
  const [state, action, pending] = useActionState<LoginState, FormData>(login, { step: "email" });

  return (
    <Card className="shadow-lg">
      {state.step === "email" ? (
        <>
          <CardHeader>
            <CardTitle className="text-xl">Admin sign-in</CardTitle>
            <CardDescription>We&apos;ll email a 6-digit code to your admin account.</CardDescription>
          </CardHeader>
          <CardContent>
            {notice && !state.error ? <Alert tone="info">{notice}</Alert> : null}
            <form action={action} className="space-y-4">
              <input type="hidden" name="intent" value="request" />
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  required
                  autoFocus
                  defaultValue={state.email}
                  placeholder="you@example.com"
                  aria-invalid={Boolean(state.error)}
                  aria-describedby={state.error ? "email-error" : undefined}
                />
              </div>
              {state.error ? (
                <Alert tone="error" id="email-error">
                  {state.error}
                </Alert>
              ) : null}
              <Button type="submit" className="w-full" disabled={pending}>
                {pending ? <Loader2 className="animate-spin" /> : <Mail />}
                Send code
              </Button>
            </form>
          </CardContent>
        </>
      ) : (
        <CodeStep state={state} action={action} pending={pending} next={next} />
      )}
    </Card>
  );
}

function CodeStep({
  state,
  action,
  pending,
  next,
}: {
  state: Extract<LoginState, { step: "code" }>;
  action: (form: FormData) => void;
  pending: boolean;
  next: string;
}) {
  const wait = useCountdown(state.sentAt + state.resendAfterSeconds * 1000);
  return (
    <>
      <CardHeader>
        <CardTitle className="text-xl">Check your email</CardTitle>
        <CardDescription>
          If <span className="font-medium text-foreground">{state.email}</span> is an admin account, a 6-digit code is
          on its way. It expires in 10 minutes.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form action={action} className="space-y-4">
          <input type="hidden" name="intent" value="verify" />
          <input type="hidden" name="next" value={next} />
          <div className="space-y-2">
            <Label htmlFor="code">Code</Label>
            <Input
              id="code"
              name="code"
              required
              autoFocus
              autoComplete="one-time-code"
              inputMode="numeric"
              pattern="[0-9 ]{6,7}"
              maxLength={7}
              placeholder="123456"
              className="h-12 text-center font-mono text-2xl tracking-[0.5em]"
              aria-invalid={Boolean(state.error)}
              aria-describedby={state.error ? "code-error" : undefined}
            />
          </div>
          {state.error ? (
            <Alert tone="error" id="code-error">
              {state.error}
            </Alert>
          ) : state.notice ? (
            <Alert tone="info">{state.notice}</Alert>
          ) : null}
          <Button type="submit" className="w-full" disabled={pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Sign in
          </Button>
        </form>
        <div className="mt-4 flex items-center justify-between text-sm">
          <form action={action}>
            <input type="hidden" name="intent" value="back" />
            <Button type="submit" variant="ghost" size="sm" disabled={pending}>
              <ArrowLeft /> Other email
            </Button>
          </form>
          <form action={action}>
            <input type="hidden" name="intent" value="resend" />
            <Button type="submit" variant="link" size="sm" disabled={pending || wait > 0}>
              {wait > 0 ? `Resend in ${wait}s` : "Resend code"}
            </Button>
          </form>
        </div>
      </CardContent>
    </>
  );
}

function Alert({ tone, id, children }: { tone: "error" | "info"; id?: string; children: React.ReactNode }) {
  return (
    <p
      id={id}
      role={tone === "error" ? "alert" : "status"}
      className={
        tone === "error"
          ? "rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
          : "mb-4 rounded-md bg-info-soft px-3 py-2 text-sm text-info"
      }
    >
      {children}
    </p>
  );
}

/** Seconds left until `until` (ms since epoch), ticking every second. */
function useCountdown(until: number) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, [until]);
  return Math.max(0, Math.ceil((until - now) / 1000));
}
