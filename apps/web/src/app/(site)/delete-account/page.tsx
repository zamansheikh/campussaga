import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Delete your account",
  description: "How to delete your VarsityKotha account, what is deleted and what is kept.",
  alternates: { canonical: "/delete-account" },
};

const mailto = "mailto:hello@silifton.com?subject=Delete%20my%20VarsityKotha%20account";
const mailtoData = "mailto:hello@silifton.com?subject=Delete%20some%20of%20my%20VarsityKotha%20data";

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
            Scroll to the bottom and tap <strong>Delete account</strong>.
          </li>
          <li>
            Tick <strong>I understand this can&apos;t be undone</strong>, then tap{" "}
            <strong>Delete my account</strong>.
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
          <li>
            Campus Voice: the link between you and your anonymous posts and comments, your &quot;Me too&quot; votes,
            the issues you follow and the reports you sent.
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
            <strong>Campus Voice posts and comments</strong> stay for other students, with no link to you. Posts and
            comments that showed your name show &quot;Deleted account&quot; instead. To hide a post or comment from
            everyone, delete it in the app first (it is then kept hidden, for moderation only).
          </li>
          <li>
            <strong>Crash reports</strong> are not linked to your account.
          </li>
          <li>
            If you used <strong>&quot;Continue with Google&quot;</strong>, Google Firebase keeps a sign-in record of your
            Google account. Ask us to remove it as part of your deletion request.
          </li>
        </ul>
        <h2 id="data">Delete some of your data and keep your account</h2>
        <p>You can delete these yourself in the app at any time:</p>
        <ul>
          <li>
            <strong>A Campus Voice issue or comment you wrote:</strong> open it, tap the <strong>⋮</strong> menu, then{" "}
            <strong>Delete</strong>. It disappears for everyone at once and is kept hidden, for moderation only.
          </li>
          <li>
            <strong>A &quot;Me too&quot; vote or a follow:</strong> tap <strong>Me too</strong> or{" "}
            <strong>Follow</strong> again. The vote or follow is deleted.
          </li>
          <li>
            <strong>A personal class:</strong> open it and tap <strong>Delete</strong>.
          </li>
          <li>
            <strong>A class group:</strong> open the group, tap the <strong>⋮</strong> menu, then{" "}
            <strong>Leave group</strong>. A CR can also <strong>Delete group</strong>, which removes its routine for
            everyone.
          </li>
          <li>
            <strong>Your name, department and batch:</strong> Profile → <strong>Edit profile</strong>.
          </li>
          <li>
            <strong>CGPA calculator entries:</strong> these are only on your phone. Delete a semester, or clear them
            all, in the CGPA calculator.
          </li>
        </ul>
        <p>
          For anything else, email <a href={mailtoData}>hello@silifton.com</a> from the address you sign in with, with
          the subject &quot;Delete some of my VarsityKotha data&quot; and what you want deleted. We do it within 7 days
          and confirm by email.
        </p>
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
            একদম নিচে স্ক্রল করে <strong>অ্যাকাউন্ট মুছে ফেলো</strong> চাপো।
          </li>
          <li>
            <strong>আমি বুঝেছি, এটি আর ফেরানো যাবে না</strong>-তে টিক দিয়ে{" "}
            <strong>আমার অ্যাকাউন্ট মুছে ফেলো</strong> চাপো।
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
          <li>
            ক্যাম্পাস ভয়েস: তোমার বেনামি পোস্ট ও মন্তব্যের সাথে তোমার সংযোগ, তোমার &quot;আমারও&quot; ভোট, ফলো করা ইস্যু
            আর তোমার পাঠানো রিপোর্ট।
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
            <strong>ক্যাম্পাস ভয়েসের পোস্ট ও মন্তব্য</strong> অন্য শিক্ষার্থীদের জন্য থেকে যায়, তোমার সাথে কোনো সংযোগ
            ছাড়া। যেগুলোতে তোমার নাম দেখানো ছিল সেখানে &quot;মুছে ফেলা অ্যাকাউন্ট&quot; দেখায়। কোনো পোস্ট বা মন্তব্য
            সবার কাছ থেকে লুকাতে চাইলে আগে অ্যাপে সেটি মুছে দাও (তারপর শুধু মডারেশনের জন্য লুকানো থাকে)।
          </li>
          <li>
            <strong>ক্র্যাশ রিপোর্ট</strong> তোমার অ্যাকাউন্টের সাথে যুক্ত নয়।
          </li>
          <li>
            &quot;Google দিয়ে চালিয়ে যাও&quot; ব্যবহার করে থাকলে Google Firebase-এ একটি সাইন-ইন রেকর্ড থাকে; মুছে
            ফেলার অনুরোধে এটিও মুছতে বলো।
          </li>
        </ul>
        <h2 id="data-bn">অ্যাকাউন্ট রেখে কিছু তথ্য মুছে ফেলো</h2>
        <p>এগুলো যেকোনো সময় নিজেই অ্যাপ থেকে মুছতে পারো:</p>
        <ul>
          <li>
            <strong>তোমার লেখা ক্যাম্পাস ভয়েস ইস্যু বা মন্তব্য:</strong> খুলে <strong>⋮</strong> মেনুতে{" "}
            <strong>মুছে ফেলো</strong> চাপো। সাথে সাথে সবার কাছ থেকে সরে যায়, শুধু মডারেশনের জন্য লুকানো থাকে।
          </li>
          <li>
            <strong>&quot;আমারও&quot; ভোট বা ফলো:</strong> আবার <strong>আমারও</strong> বা <strong>ফলো করো</strong>{" "}
            চাপো। ভোট বা ফলো মুছে যায়।
          </li>
          <li>
            <strong>ব্যক্তিগত ক্লাস:</strong> খুলে <strong>মুছে ফেলো</strong> চাপো।
          </li>
          <li>
            <strong>ক্লাস গ্রুপ:</strong> গ্রুপ খুলে <strong>⋮</strong> মেনুতে <strong>গ্রুপ ছেড়ে দাও</strong>। সিআর
            চাইলে <strong>গ্রুপ মুছে ফেলো</strong> দিয়ে সবার জন্য রুটিন সরাতে পারে।
          </li>
          <li>
            <strong>নাম, বিভাগ ও ব্যাচ:</strong> প্রোফাইল → <strong>প্রোফাইল সম্পাদনা</strong>।
          </li>
          <li>
            <strong>সিজিপিএ ক্যালকুলেটরের তথ্য:</strong> শুধু তোমার ফোনে থাকে; ক্যালকুলেটর থেকেই সেমিস্টার বা সব তথ্য
            মুছতে পারো।
          </li>
        </ul>
        <p>
          অন্য কিছু মুছতে চাইলে যে ঠিকানা দিয়ে সাইন ইন করো সেখান থেকে <a href={mailtoData}>hello@silifton.com</a>{" "}
          ঠিকানায় &quot;Delete some of my VarsityKotha data&quot; বিষয়ে লিখে জানাও কী মুছতে চাও। ৭ দিনের মধ্যে মুছে
          ইমেইলে জানানো হবে।
        </p>
        <p>
          বিস্তারিত: <Link href="/privacy#bn">গোপনীয়তা নীতি</Link>।
        </p>
      </section>
    </article>
  );
}
