import type { Metadata } from "next";
import Link from "next/link";

import { BrandMark } from "@/components/site/brand-mark";
import { ThemeToggle } from "@/components/theme-toggle";

import { LoginForm } from "./login-form";

export const metadata: Metadata = {
  title: "Admin sign-in",
  robots: { index: false, follow: false },
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; expired?: string; error?: string }>;
}) {
  const { next, expired, error } = await searchParams;
  const notice =
    error === "not_admin"
      ? "That account isn't an admin or a moderator. Sign in with a staff account."
      : expired
        ? "Your session ended. Please sign in again."
        : undefined;
  return (
    <div className="relative flex min-h-dvh flex-col items-center justify-center px-4 py-12">
      <div className="absolute top-4 right-4">
        <ThemeToggle />
      </div>
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 -z-10 mx-auto h-72 max-w-xl rounded-full bg-primary/15 blur-3xl"
      />
      <div className="w-full max-w-sm">
        <Link href="/" className="mb-8 flex items-center justify-center gap-2.5 font-semibold">
          <BrandMark className="size-10 rounded-xl" />
          <span className="text-xl tracking-tight">VarsityKotha</span>
        </Link>
        <LoginForm next={next ?? ""} notice={notice} />
        <p className="mt-6 text-center text-xs text-muted-foreground">
          For VarsityKotha staff only. Every action is recorded.
        </p>
      </div>
    </div>
  );
}
