"use server";

import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { PushResult } from "@/lib/admin/types";

const text = (max: number) => z.string().trim().max(max);

const schema = z
  .object({
    target: z.enum(["user", "all"]),
    userId: z.uuid().optional(),
    title: text(80).min(1, "Add an English title"),
    body: text(240).min(1, "Add an English message"),
    titleBn: text(80),
    bodyBn: text(240),
  })
  .refine((v) => v.target === "all" || Boolean(v.userId), { message: "Choose who gets it", path: ["userId"] });

export type PushInput = z.input<typeof schema>;

export async function sendPush(input: PushInput): Promise<ActionResult<PushResult>> {
  const parsed = schema.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues.map((i) => i.message).join(" · ") };
  const { titleBn, bodyBn, userId, ...rest } = parsed.data;
  try {
    const res = await api<PushResult>("/admin/push", {
      method: "POST",
      body: {
        ...rest,
        ...(rest.target === "user" ? { userId } : {}),
        ...(titleBn ? { titleBn } : {}),
        ...(bodyBn ? { bodyBn } : {}),
      },
    });
    const devices = res.devices === 1 ? "1 phone" : `${res.devices} phones`;
    const users = res.users === 1 ? "1 person" : `${res.users} people`;
    return {
      ok: true,
      data: res,
      message: res.devices === 0 ? "Nobody to send to: no phone is registered for push." : `Sent to ${devices} (${users}).`,
    };
  } catch (e) {
    return failure(e);
  }
}
