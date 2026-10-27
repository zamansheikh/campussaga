/** Public facts about the product, used across pages and metadata. */
export const site = {
  name: "Campus Saga",
  url: process.env.SITE_URL ?? "https://campus.silifton.com",
  description:
    "Campus Saga is a student app for Bangladeshi universities: class routine, reminders, and a safe, anonymous voice to get campus problems fixed.",
  supportEmail: "hello@silifton.com",
  company: { name: "Silifton", url: "https://silifton.com" },
} as const;
