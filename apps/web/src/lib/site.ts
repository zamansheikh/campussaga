/** Public facts about the product, used across pages and metadata. */
export const site = {
  name: "VarsityKotha",
  url: process.env.SITE_URL ?? "https://varsitykotha.com",
  description:
    "VarsityKotha is a student app for Bangladeshi universities: class routine, reminders, and a safe, anonymous voice to get campus problems fixed.",
  supportEmail: "hello@silifton.com",
  company: { name: "Silifton", url: "https://silifton.com" },
} as const;
