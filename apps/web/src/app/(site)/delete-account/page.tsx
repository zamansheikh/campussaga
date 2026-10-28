import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Delete your account",
  description: "How to delete your VarsityKotha account, what is deleted and what is kept.",
  alternates: { canonical: "/delete-account" },
};

const mailto = "mailto:hello@silifton.com?subject=Delete%20my%20VarsityKotha%20account";

export default function DeleteAccountPage() {
  return (
    <article className="prose-page mx-auto max-w-3xl px-4 py-12">
      <section lang="en">
        <h1>Delete your VarsityKotha account</h1>
        <p>
          <a href="#bn">বাংলায় পড়ো</a>
        </p>

        <h2>In the app (immediate)</h2>
        <ol>
          <li>
            Open VarsityKotha and go to the <strong>Profile</strong> tab.
          </li>
          <li>
            Scroll down and tap <strong>Delete account</strong>.
          </li>
          <li>
            Confirm with <strong>Delete my account</strong>.
          </li>
        </ol>
        <p>Your account is deleted at once and you are signed out on every device.</p>

        <h2>By email (if you can&apos;t open the app)</h2>
        <p>
          Send an email to <a href={mailto}>hello@silifton.com</a>{" "}
          <strong>from the email address you sign in with</strong> (your university email, or your Google account if
          you signed in with Google) with the subject &quot;Delete my VarsityKotha account&quot;. We delete the account
          within 7 days and confirm by email. Sending from the same address lets us check the request really comes from
          you.
        </p>

        <h2>What is deleted</h2>
        <ul>
          <li>Your profile: email, university email, name, department and batch.</li>
          <li>All your sessions (you are signed out everywhere).</li>
          <li>Any pending sign-in code.</li>
          <li>
            Your class group memberships, hidden courses, personal classes and push notification tokens. Groups you are
            in stay for the other members; if you were their only CR, the longest member becomes CR.
          </li>
        </ul>

        <h2>What is kept, and for how long</h2>
        <ul>
          <li>
            <strong>Encrypted backups</strong> may still contain your account for up to 6 months, until they are
            deleted. Deleted accounts are never restored from them except to recover the whole service after a failure,
            and are then deleted again.
          </li>
          <li>
            <strong>Server logs</strong> that contain your internal account ID are deleted after at most 30 days.
          </li>
          <li>
            <strong>Crash reports</strong> are not linked to your account.
          </li>
          <li>
            If you used <strong>&quot;Continue with Google&quot;</strong>, Google Firebase keeps a sign-in record of your
            Google account. Ask us to remove it as part of your deletion request.
          </li>
        </ul>
        <p>
          More details: <Link href="/privacy">Privacy Policy</Link>.
        </p>
      </section>

      <section lang="bn" id="bn" className="mt-16 border-t-2 pt-10">
        <h1>ভার্সিটি কথা অ্যাকাউন্ট মুছে ফেলো</h1>

        <h2>অ্যাপ থেকে (সাথে সাথে)</h2>
        <ol>
          <li>
            ভার্সিটি কথা খুলে <strong>প্রোফাইল</strong> ট্যাবে যাও।
          </li>
          <li>
            নিচে স্ক্রল করে <strong>অ্যাকাউন্ট মুছে ফেলো</strong> চাপো।
          </li>
          <li>
            <strong>আমার অ্যাকাউন্ট মুছে ফেলো</strong> চেপে নিশ্চিত করো।
          </li>
        </ol>
        <p>অ্যাকাউন্ট সাথে সাথে মুছে যাবে এবং সব ডিভাইস থেকে সাইন আউট হয়ে যাবে।</p>

        <h2>ইমেইলে (অ্যাপ খুলতে না পারলে)</h2>
        <p>
          <strong>যে ইমেইল দিয়ে সাইন ইন করো সেখান থেকে</strong> (বিশ্ববিদ্যালয়ের ইমেইল, অথবা Google দিয়ে সাইন ইন করলে
          সেই Google অ্যাকাউন্ট) <a href={mailto}>hello@silifton.com</a> ঠিকানায় &quot;Delete my VarsityKotha
          account&quot; বিষয় দিয়ে ইমেইল পাঠাও। ৭ দিনের মধ্যে অ্যাকাউন্ট মুছে ইমেইলে জানানো হবে।
        </p>

        <h2>কী মুছে যায়</h2>
        <ul>
          <li>তোমার প্রোফাইল: ইমেইল, বিশ্ববিদ্যালয়ের ইমেইল, নাম, বিভাগ ও ব্যাচ।</li>
          <li>তোমার সব সেশন।</li>
          <li>অপেক্ষমাণ সাইন-ইন কোড।</li>
          <li>
            তোমার ক্লাস গ্রুপের সদস্যপদ, লুকানো কোর্স, ব্যক্তিগত ক্লাস ও পুশ নোটিফিকেশন টোকেন। গ্রুপগুলো অন্য সদস্যদের
            জন্য থেকে যায়; তুমি একমাত্র সিআর হলে সবচেয়ে পুরোনো সদস্য সিআর হয়ে যায়।
          </li>
        </ul>

        <h2>কী থেকে যায় এবং কতদিন</h2>
        <ul>
          <li>
            <strong>এনক্রিপ্টেড ব্যাকআপে</strong> সর্বোচ্চ ৬ মাস থাকতে পারে, তারপর মুছে যায়।
          </li>
          <li>
            তোমার অভ্যন্তরীণ আইডিসহ <strong>সার্ভার লগ</strong> সর্বোচ্চ ৩০ দিনে মুছে যায়।
          </li>
          <li>
            <strong>ক্র্যাশ রিপোর্ট</strong> তোমার অ্যাকাউন্টের সাথে যুক্ত নয়।
          </li>
          <li>
            &quot;Google দিয়ে চালিয়ে যাও&quot; ব্যবহার করে থাকলে Google Firebase-এ একটি সাইন-ইন রেকর্ড থাকে; মুছে
            ফেলার অনুরোধে এটিও মুছতে বলো।
          </li>
        </ul>
        <p>
          বিস্তারিত: <Link href="/privacy#bn">গোপনীয়তা নীতি</Link>।
        </p>
      </section>
    </article>
  );
}
