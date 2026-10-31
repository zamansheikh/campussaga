/** Public facts about the product, used across pages and metadata. */
export const site = {
  name: "VarsityKotha",
  url: process.env.SITE_URL ?? "https://varsitykotha.com",
  description:
    "VarsityKotha is a student app for Bangladeshi universities: class routine, reminders, and a safe, anonymous voice to get campus problems fixed.",
  supportEmail: "hello@silifton.com",
  company: { name: "Silifton", url: "https://silifton.com" },
  // live: the landing page links to the listing; false shows "Coming soon" instead.
  playStore: { url: "https://play.google.com/store/apps/details?id=com.silifton.varsitykotha", live: true },
  androidPackage: "com.silifton.varsitykotha",
} as const;

/** The Play listing; [join] passes a group code through the install referrer. */
export function playUrl(join?: string): string {
  if (!join) return site.playStore.url;
  const referrer = `utm_source=invite&utm_medium=link&join=${join}`;
  return `${site.playStore.url}&referrer=${encodeURIComponent(referrer)}`;
}


/** The Play listing for a personal invite link: the install referrer carries the inviter's code. */
export function inviteUrl(ref: string): string {
  return `${site.playStore.url}&referrer=${encodeURIComponent(`utm_source=invite&ref=${ref}`)}`;
}
