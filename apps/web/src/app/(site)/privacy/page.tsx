import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "How VarsityKotha collects, uses and protects your information.",
  alternates: { canonical: "/privacy" },
};

function Table({ head, rows }: { head: string[]; rows: React.ReactNode[][] }) {
  return (
    <div className="-mx-4 overflow-x-auto px-4">
      <table>
        <thead>
          <tr>
            {head.map((h) => (
              <th key={h} scope="col">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i}>
              {r.map((c, j) => (
                <td key={j}>{c}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function PrivacyPage() {
  return (
    <article className="prose-page mx-auto max-w-3xl px-4 py-12">
      <section lang="en">
        <h1>Privacy Policy</h1>
        <p className="text-muted-foreground">Effective 28 October 2026</p>
        <p>
          <a href="#bn">বাংলায় পড়ো</a>
        </p>

        <p>
          VarsityKotha (&quot;the app&quot;, &quot;we&quot;) is a student app for universities in Bangladesh, made by{" "}
          <a href="https://silifton.com">Silifton</a>. This policy explains what information the app and its server
          collect, why, who else handles it, how long we keep it, and the choices you have. We wrote it to match what
          the app actually does today. When we add features that use your information in a new way, we will update this
          page first and tell you in the app.
        </p>

        <h2>The short version</h2>
        <ul>
          <li>
            You sign in with your <strong>university email</strong>, which shows you are a student (<em>verified</em>).
            If your university gives no email, you can sign in with a Google account, choose your university, and show
            as <em>not verified</em> until you verify with a university email.
          </li>
          <li>
            We store only what the app needs: your email, your university, the name, department and batch you enter,
            and the class groups, routines and personal classes you use.
          </li>
          <li>
            <strong>Campus Voice posts are anonymous by default.</strong> No student, CR, staff member or university
            official can see who wrote an anonymous post.
          </li>
          <li>
            <strong>No ads, no selling or renting your data, no tracking analytics.</strong>
          </li>
          <li>
            You can edit your profile and <strong>delete your account at any time</strong> in the app.
          </li>
        </ul>

        <h2>What we collect</h2>
        <Table
          head={["Information", "Why"]}
          rows={[
            [
              <strong key="k">University email address</strong>,
              <>
                To sign you in and to confirm which university you belong to (from the email&apos;s domain, e.g.{" "}
                <code>diu.edu.bd</code>). This makes you a <em>verified</em> student.
              </>,
            ],
            [
              <strong key="k">Google account email (if you have no university email)</strong>,
              <>
                To sign you in. You choose your university yourself and are shown as <em>not verified</em> (also to
                your class group&apos;s CRs). You can verify later with a code sent to a university email; we then
                store that university email too.
              </>,
            ],
            [
              <strong key="k">Your university</strong>,
              "Worked out from your email domain. Used to show you your own university.",
            ],
            [
              <strong key="k">Name, department and batch</strong>,
              "Entered by you, so classmates can recognise you in class groups and so we can suggest the right class. If you sign in with Google, your name from Google is filled in for you and you can change it.",
            ],
            [
              <strong key="k">Sign-in codes</strong>,
              "The 6-digit code we email you. We store only a one-way scrambled (hashed) form of it, never the code itself. It expires after 10 minutes.",
            ],
            [
              <strong key="k">Session information</strong>,
              "To keep you signed in on each device: a session record with the time it was created and last used, your device's app identifier text (user agent), and a scrambled (hashed) form of the sign-in token. The token itself is kept only on your phone, in its secure storage (Keychain or Android Keystore).",
            ],
            [
              <strong key="k">Class groups and routines</strong>,
              "The groups you create or join with a code, your role (CR or member), the weekly routine and one-day changes the CR enters (course, teacher, room, time, notes) and the CR's announcements. Everyone in a group sees its routine, changes and announcements. Only CRs see the member list, and only names (never emails). Courses you hide from your routine are stored so they stay hidden on your other devices.",
            ],
            [
              <strong key="k">Personal classes</strong>,
              "Entries you add for yourself (for example a tuition): name, details, place, day and time. Only you can see them.",
            ],
            [
              <strong key="k">Find your class</strong>,
              "If your CR keeps your class findable, students of your university can find it by search and see its department, batch, section, courses, teachers and the CR's name. The CR can turn this off.",
            ],
            [
              <strong key="k">Campus Voice posts</strong>,
              <>
                The issues and comments you post, the place you type (for example &quot;Hall 2&quot;), your &quot;Me
                too&quot; votes, the issues you follow and the reports you send. Posts are <strong>anonymous</strong>{" "}
                unless you choose to show your name. The link between you and an anonymous post is kept separately and
                is never shown on any screen, to any student, CR, staff member or university official; we use it only
                to show you your own posts and to block someone who breaks the rules. Students and officials of your
                university see the posts. Posts in the Safety category are private: only moderators and your
                university&apos;s officials see them. Moderators see reported posts and the reasons given, never who
                reported them.
              </>,
            ],
            [
              <strong key="k">Photos you attach to Campus Voice</strong>,
              "Up to 4 photos per post, chosen with your phone's photo picker: the app cannot see your other photos. Our server re-encodes and shrinks each photo, which removes hidden details such as location, phone model and the time it was taken, and checks it with a nudity filter that runs on our own server (photos are not sent to any outside service for this). Photos you add but don't post are deleted after 24 hours.",
            ],
            [
              <strong key="k">Push notification token</strong>,
              "A token from Firebase Cloud Messaging, your phone type and the app language, so we can tell you when your CR changes a class or posts an announcement. It is tied to your sign-in on that phone: signing out stops notifications there.",
            ],
            [
              <strong key="k">Department suggestions</strong>,
              <>
                When you type your department, we show department names other students at <em>your</em> university
                entered. Only the department names are shared, never who entered them.
              </>,
            ],
            [
              <strong key="k">Crash reports</strong>,
              <>
                If the app crashes or hits an unexpected error, a report is sent so we can fix it: the error and where
                in the app it happened, device model, operating system and app version, and a random installation
                identifier. Crash reports do <strong>not</strong> include your email, name, profile or any user ID.
                They are sent only from released versions of the app.
              </>,
            ],
            [
              <strong key="k">Server logs</strong>,
              "To keep the service running and secure, our server records which part of the API was called, the result and how long it took. For signed-in requests this includes your internal account ID. Your IP address is used briefly, in memory only, to limit repeated sign-in attempts; it is not written to the logs.",
            ],
            [
              <strong key="k">Settings on your phone</strong>,
              "Your theme and language, class reminder choices, your CGPA calculator entries, your chosen bus stop and a copy of your routine (so the app works offline) are saved only on your phone. Class reminders are scheduled on your phone; we don't need to know about them.",
            ],
          ]}
        />
        <p>
          <strong>Your location.</strong> Only if you tap &quot;Where am I&quot; on a bus route map, the app asks for
          your phone&apos;s location and uses it on your phone, to show you on the map and find your nearest stop. It
          is not sent to us and stops when you leave the map. A transport rep placing a bus stop can tap &quot;Use my
          location&quot;: then the stop&apos;s position (one point on the map, not who was there or when) is saved
          with the route.
        </p>
        <p>
          We do not collect your phone number, contacts or location history, and we never see photos or files you
          don&apos;t choose to attach. The app does not use advertising identifiers.
        </p>

        <h2>Who else handles your information</h2>
        <p>
          We use a small number of service providers, only for the purposes below. They may process data outside
          Bangladesh.
        </p>
        <Table
          head={["Provider", "What they do for us", "Information involved"]}
          rows={[
            [
              "Google Firebase Authentication",
              'Only if you choose "Continue with Google": handles the Google sign-in and confirms your Google account to our server.',
              "Your Google account email, name and profile picture link, kept in Firebase's sign-in records.",
            ],
            ["Google Firebase Crashlytics", "Collects crash reports.", "The crash report data described above."],
            [
              "Google Firebase Cloud Messaging",
              "Delivers push notifications to your phone (and Apple's push service on iPhones).",
              'Your push token and the notification text (for example "CSE311 cancelled tomorrow").',
            ],
            ["Resend", "Delivers the email with your sign-in code.", "Your email address and the email's content."],
            [
              "OpenStreetMap Foundation",
              "Serves the map images on bus route maps, and finds places by name when a transport rep places a stop.",
              "Your IP address and the map area your phone loads (as with any website; after “Where am I” that is the area around you), and the place name a rep searches for. No account details.",
            ],
            [
              "Server and storage providers",
              "Run our server, database, photo storage and encrypted backups.",
              "The information stored in our database.",
            ],
          ]}
        />
        <p>
          Google&apos;s privacy policy: <a href="https://policies.google.com/privacy">policies.google.com/privacy</a>.
          Resend&apos;s privacy policy:{" "}
          <a href="https://resend.com/legal/privacy-policy">resend.com/legal/privacy-policy</a>. OpenStreetMap&apos;s
          privacy policy: <a href="https://osmfoundation.org/wiki/Privacy_Policy">osmfoundation.org/wiki/Privacy_Policy</a>.
        </p>
        <p>
          We do not sell, rent or trade your information, and we do not share it with advertisers. We may disclose
          information if required by Bangladeshi law or a valid legal order, and we will tell you about such a request
          when the law allows.
        </p>

        <h2>How long we keep it</h2>
        <ul>
          <li>
            <strong>Your account and profile:</strong> until you delete your account.
          </li>
          <li>
            <strong>Class groups:</strong> until the CR deletes the group or its last member leaves. One-day changes are
            no longer shown a day after their date; announcements after 30 days (unless pinned). Your membership,
            hidden courses and personal classes are deleted with your account.
          </li>
          <li>
            <strong>Campus Voice:</strong> posts, comments and photos stay until the author deletes them or moderators
            remove them. Deleted and removed posts are hidden from everyone at once and kept, hidden, for moderation.
            When you delete your account, your link to your anonymous posts and your votes, follows and reports are
            deleted; the posts stay with no link to you, and posts that showed your name show &quot;Deleted
            account&quot;.
          </li>
          <li>
            <strong>Push tokens:</strong> stop being used when you sign out; deleted with your account or when Firebase
            reports the app was removed from the phone.
          </li>
          <li>
            <strong>Sign-in codes:</strong> expire after 10 minutes; deleted within about an hour after that.
          </li>
          <li>
            <strong>Ended sessions</strong> (signed out, expired or revoked): deleted after 7 days.
          </li>
          <li>
            <strong>Server logs:</strong> deleted after at most 30 days.
          </li>
          <li>
            <strong>Backups:</strong> encrypted database backups are kept for up to 6 months for disaster recovery,
            then deleted. Deleted accounts are never restored from a backup except to recover the whole service after a
            failure, and are then deleted again.
          </li>
        </ul>

        <h2>Your choices and rights</h2>
        <ul>
          <li>
            <strong>See and correct your information:</strong> Profile tab → your account card and &quot;Edit
            profile&quot;.
          </li>
          <li>
            <strong>Sign out everywhere:</strong> ends all your sessions on all devices.
          </li>
          <li>
            <strong>Delete your account:</strong> Profile tab → &quot;Delete account&quot;. This immediately and
            permanently deletes your profile and all your sessions. See{" "}
            <Link href="/delete-account">how to delete your account</Link> (also possible by email).
          </li>
          <li>
            <strong>Questions or requests:</strong> email <a href="mailto:hello@silifton.com">hello@silifton.com</a>.
            We answer within 30 days.
          </li>
        </ul>

        <h2>Security</h2>
        <p>
          All traffic between the app and our server is encrypted (HTTPS). Sign-in codes and session tokens are stored
          only in scrambled (hashed) form on the server. Each request checks that your session is still active, so
          signing out or deleting your account takes effect immediately. Backups are encrypted. No system is perfectly
          secure, but we work to protect your information and will tell affected users promptly if a breach happens.
        </p>

        <h2>Children</h2>
        <p>
          VarsityKotha is for university students. It is not intended for children under 13, and we do not knowingly
          collect their information.
        </p>

        <h2>Changes to this policy</h2>
        <p>
          If we change this policy, we will update the date above. If the change is significant, for example a new
          kind of information or a new provider, we will tell you in the app before it takes effect.
        </p>

        <h2>Contact</h2>
        <p>
          Silifton · <a href="mailto:hello@silifton.com">hello@silifton.com</a> ·{" "}
          <a href="https://silifton.com">silifton.com</a>
        </p>
      </section>

      <section lang="bn" id="bn" className="mt-16 border-t-2 pt-10">
        <h1>গোপনীয়তা নীতি</h1>
        <p className="text-muted-foreground">কার্যকর: ২৮ অক্টোবর ২০২৬</p>
        <p>
          ভার্সিটি কথা (&quot;অ্যাপ&quot;, &quot;আমরা&quot;) বাংলাদেশের বিশ্ববিদ্যালয়ের শিক্ষার্থীদের জন্য একটি অ্যাপ,
          তৈরি করেছে <a href="https://silifton.com">সিলিফটন</a>। এই নীতিতে বলা হয়েছে অ্যাপ ও এর সার্ভার কী তথ্য নেয়, কেন
          নেয়, আর কে কে তা ব্যবহার করে, কতদিন রাখা হয় এবং তোমার কী কী সুযোগ আছে। ইংরেজি ও বাংলা সংস্করণের মধ্যে কোনো
          অমিল থাকলে ইংরেজি সংস্করণ প্রযোজ্য হবে।
        </p>

        <h2>সংক্ষেপে</h2>
        <ul>
          <li>
            তুমি সাইন ইন করো <strong>বিশ্ববিদ্যালয়ের ইমেইল</strong> দিয়ে, যা দেখায় তুমি শিক্ষার্থী (
            <em>যাচাই করা</em>)। বিশ্ববিদ্যালয় ইমেইল না দিলে Google অ্যাকাউন্ট দিয়ে সাইন ইন করে বিশ্ববিদ্যালয় বেছে নিতে
            পারো; বিশ্ববিদ্যালয়ের ইমেইল দিয়ে যাচাই না করা পর্যন্ত তুমি <em>যাচাই করা হয়নি</em> হিসেবে দেখাবে।
          </li>
          <li>
            আমরা শুধু প্রয়োজনীয় তথ্য রাখি: তোমার ইমেইল, বিশ্ববিদ্যালয়, তুমি যে নাম, বিভাগ ও ব্যাচ দাও, এবং তোমার ক্লাস
            গ্রুপ, রুটিন ও ব্যক্তিগত ক্লাস।
          </li>
          <li>
            <strong>ক্যাম্পাস ভয়েসের পোস্ট স্বাভাবিকভাবে বেনামি।</strong> বেনামি পোস্ট কে লিখেছে তা কোনো শিক্ষার্থী,
            সিআর, স্টাফ বা বিশ্ববিদ্যালয়ের কর্মকর্তা দেখতে পারে না।
          </li>
          <li>
            <strong>কোনো বিজ্ঞাপন নেই, তথ্য বিক্রি বা ভাড়া দেওয়া হয় না, কোনো ট্র্যাকিং অ্যানালিটিক্স নেই।</strong>
          </li>
          <li>
            যেকোনো সময় অ্যাপে প্রোফাইল বদলাতে এবং <strong>অ্যাকাউন্ট মুছে ফেলতে</strong> পারো।
          </li>
        </ul>

        <h2>আমরা কী তথ্য নিই</h2>
        <ul>
          <li>
            <strong>বিশ্ববিদ্যালয়ের ইমেইল:</strong> সাইন ইন করতে এবং ইমেইলের ডোমেইন থেকে তোমার বিশ্ববিদ্যালয় চিনতে;
            এতে তুমি <em>যাচাই করা</em> শিক্ষার্থী।
          </li>
          <li>
            <strong>Google অ্যাকাউন্টের ইমেইল (বিশ্ববিদ্যালয়ের ইমেইল না থাকলে):</strong> সাইন ইন করতে। বিশ্ববিদ্যালয়
            তুমি নিজে বেছে নাও এবং <em>যাচাই করা হয়নি</em> হিসেবে দেখাবে (ক্লাস গ্রুপের সিআর-দের কাছেও)। পরে
            বিশ্ববিদ্যালয়ের ইমেইলে পাঠানো কোড দিয়ে যাচাই করতে পারো; তখন সেই ইমেইলটিও রাখা হয়।
          </li>
          <li>
            <strong>নাম, বিভাগ ও ব্যাচ:</strong> তুমি নিজে দাও, যাতে ক্লাস গ্রুপে সহপাঠীরা তোমাকে চিনতে পারে। Google দিয়ে
            সাইন ইন করলে Google-এর নামটি আগে থেকে বসানো থাকে, তুমি বদলাতে পারো।
          </li>
          <li>
            <strong>সাইন-ইন কোড:</strong> সার্ভারে কোডটি সরাসরি রাখা হয় না, শুধু একমুখী গোপন (হ্যাশ) রূপে রাখা হয়। ১০
            মিনিট পর মেয়াদ শেষ।
          </li>
          <li>
            <strong>সেশনের তথ্য:</strong> প্রতিটি ডিভাইসে সাইন ইন রাখার জন্য সেশনের সময়, ডিভাইসের অ্যাপ-পরিচয় (user
            agent) আর টোকেনের হ্যাশ। আসল টোকেন শুধু তোমার ফোনের নিরাপদ স্টোরেজে থাকে।
          </li>
          <li>
            <strong>ক্লাস গ্রুপ ও রুটিন:</strong> তুমি যে গ্রুপ তৈরি করো বা কোড দিয়ে যোগ দাও, তোমার ভূমিকা (সিআর বা
            সদস্য), সিআর-এর দেওয়া সাপ্তাহিক রুটিন ও এক দিনের পরিবর্তন (কোর্স, শিক্ষক, রুম, সময়, নোট) এবং সিআর-এর
            ঘোষণা। গ্রুপের সবাই এগুলো দেখে। সদস্য তালিকা শুধু সিআর দেখে, আর শুধু নাম (ইমেইল কখনো নয়)। রুটিন থেকে লুকানো
            কোর্সগুলো রাখা হয় যাতে অন্য ডিভাইসেও লুকানো থাকে।
          </li>
          <li>
            <strong>ব্যক্তিগত ক্লাস:</strong> নিজের জন্য যোগ করা এন্ট্রি (যেমন টিউশন): নাম, বিস্তারিত, জায়গা, দিন ও
            সময়। শুধু তুমি দেখো।
          </li>
          <li>
            <strong>ক্লাস খুঁজে নাও:</strong> সিআর ক্লাসটি খোঁজার যোগ্য রাখলে তোমার বিশ্ববিদ্যালয়ের শিক্ষার্থীরা খুঁজে
            বিভাগ, ব্যাচ, সেকশন, কোর্স, শিক্ষক ও সিআর-এর নাম দেখতে পায়। সিআর এটি বন্ধ করতে পারে।
          </li>
          <li>
            <strong>ক্যাম্পাস ভয়েসের পোস্ট:</strong> তোমার দেওয়া ইস্যু ও মন্তব্য, তুমি যে জায়গা লেখো (যেমন &quot;হল
            ২&quot;), তোমার &quot;আমারও&quot; ভোট, যে ইস্যু ফলো করো আর যে রিপোর্ট পাঠাও। নাম দেখাতে না চাইলে পোস্ট{" "}
            <strong>বেনামি</strong>। বেনামি পোস্টের সাথে তোমার সংযোগ আলাদাভাবে রাখা হয় এবং কোনো স্ক্রিনে, কোনো
            শিক্ষার্থী, সিআর, স্টাফ বা বিশ্ববিদ্যালয়ের কর্মকর্তাকে কখনো দেখানো হয় না; শুধু তোমার নিজের পোস্ট দেখাতে
            আর নিয়ম ভাঙলে কাউকে আটকাতে এটি ব্যবহার হয়। তোমার বিশ্ববিদ্যালয়ের শিক্ষার্থী ও কর্মকর্তারা পোস্ট দেখে।
            নিরাপত্তা বিভাগের পোস্ট গোপন: শুধু মডারেটর ও তোমার বিশ্ববিদ্যালয়ের কর্মকর্তারা দেখে। মডারেটররা রিপোর্ট
            করা পোস্ট ও কারণ দেখে, কে রিপোর্ট করেছে তা কখনো নয়।
          </li>
          <li>
            <strong>ক্যাম্পাস ভয়েসে দেওয়া ছবি:</strong> প্রতি পোস্টে সর্বোচ্চ ৪টি ছবি, ফোনের ফটো পিকার দিয়ে বাছাই করা;
            অ্যাপ তোমার অন্য ছবি দেখতে পারে না। আমাদের সার্ভার প্রতিটি ছবি নতুন করে তৈরি ও ছোট করে, এতে লোকেশন, ফোনের
            মডেল ও ছবি তোলার সময়ের মতো লুকানো তথ্য মুছে যায়, আর আমাদের নিজের সার্ভারে চলা একটি অশ্লীলতা-ফিল্টার দিয়ে
            পরীক্ষা করে (এজন্য ছবি বাইরের কোনো সেবায় পাঠানো হয় না)। যোগ করে পোস্ট না করা ছবি ২৪ ঘণ্টা পর মুছে যায়।
          </li>
          <li>
            <strong>পুশ নোটিফিকেশন টোকেন:</strong> Firebase Cloud Messaging-এর একটি টোকেন, ফোনের ধরন ও অ্যাপের ভাষা,
            যাতে সিআর ক্লাস বদলালে বা ঘোষণা দিলে তোমাকে জানাতে পারি। এটি ওই ফোনের সাইন-ইনের সাথে যুক্ত: সাইন আউট করলে
            ওই ফোনে নোটিফিকেশন বন্ধ হয়।
          </li>
          <li>
            <strong>বিভাগের সাজেশন:</strong> তোমার বিশ্ববিদ্যালয়ের অন্য শিক্ষার্থীরা যে বিভাগের নাম লিখেছে, শুধু সেই
            নামগুলো দেখানো হয়, কে লিখেছে তা কখনো নয়।
          </li>
          <li>
            <strong>ক্র্যাশ রিপোর্ট:</strong> অ্যাপ বন্ধ হয়ে গেলে ত্রুটির বিবরণ, ডিভাইসের মডেল, অপারেটিং সিস্টেম ও অ্যাপের
            সংস্করণ এবং একটি র‍্যান্ডম ইনস্টলেশন আইডি পাঠানো হয়। এতে তোমার ইমেইল, নাম, প্রোফাইল বা কোনো ইউজার আইডি থাকে{" "}
            <strong>না</strong>।
          </li>
          <li>
            <strong>সার্ভার লগ:</strong> সেবা চালু ও নিরাপদ রাখতে কোন অংশ ব্যবহার হলো, ফলাফল ও সময় লেখা হয়; সাইন ইন
            অবস্থায় তোমার অভ্যন্তরীণ অ্যাকাউন্ট আইডিও থাকে। বারবার সাইন-ইন চেষ্টা আটকাতে তোমার IP ঠিকানা কিছুক্ষণ শুধু
            মেমরিতে ব্যবহার হয়, লগে লেখা হয় না।
          </li>
          <li>
            <strong>ফোনের সেটিংস:</strong> থিম, ভাষা, ক্লাস রিমাইন্ডারের পছন্দ, সিজিপিএ ক্যালকুলেটরের তথ্য, বেছে নেওয়া বাস
            স্টপ এবং রুটিনের একটি কপি (অফলাইনে চালানোর জন্য) শুধু তোমার ফোনে থাকে। ক্লাস রিমাইন্ডার ফোনেই সেট হয়, আমাদের জানার দরকার হয় না।
          </li>
        </ul>
        <p>
          <strong>তোমার লোকেশন:</strong> বাসের রুটের ম্যাপে শুধু &quot;আমি কোথায়&quot; চাপলে অ্যাপ ফোনের লোকেশন চায় এবং
          তোমার ফোনেই ব্যবহার করে, ম্যাপে তোমাকে দেখাতে ও সবচেয়ে কাছের স্টপ খুঁজতে। এটি আমাদের কাছে পাঠানো হয় না এবং
          ম্যাপ থেকে বের হলে বন্ধ হয়। ট্রান্সপোর্ট প্রতিনিধি স্টপ বসানোর সময় &quot;আমার লোকেশন&quot; চাপলে শুধু স্টপের
          অবস্থান (ম্যাপের একটি বিন্দু, কে বা কখন ছিল তা নয়) রুটের সাথে সংরক্ষিত হয়।
        </p>
        <p>
          আমরা তোমার ফোন নম্বর, কন্টাক্ট বা লোকেশনের ইতিহাস নিই না, আর তুমি নিজে যুক্ত না করলে কোনো ছবি বা ফাইল দেখি
          না। অ্যাপে বিজ্ঞাপনের আইডি ব্যবহার হয় না।
        </p>

        <h2>আর কারা তথ্য ব্যবহার করে</h2>
        <ul>
          <li>
            <strong>Google Firebase Authentication:</strong> শুধু &quot;Google দিয়ে চালিয়ে যাও&quot; বেছে নিলে, Google
            সাইন-ইন সম্পন্ন করে (তোমার Google ইমেইল, নাম ও প্রোফাইল ছবির লিংক)।
          </li>
          <li>
            <strong>Google Firebase Crashlytics:</strong> ক্র্যাশ রিপোর্ট সংগ্রহ করে।
          </li>
          <li>
            <strong>Google Firebase Cloud Messaging:</strong> তোমার ফোনে পুশ নোটিফিকেশন পৌঁছায় (আইফোনে Apple-এর পুশ
            সেবার মাধ্যমে); পুশ টোকেন ও নোটিফিকেশনের লেখা।
          </li>
          <li>
            <strong>Resend:</strong> সাইন-ইন কোডসহ ইমেইল পাঠায় (তোমার ইমেইল ঠিকানা ও ইমেইলের লেখা)।
          </li>
          <li>
            <strong>OpenStreetMap Foundation:</strong> বাসের রুটের ম্যাপের ছবি দেখায়, আর ট্রান্সপোর্ট প্রতিনিধি স্টপ বসানোর
            সময় নাম দিয়ে জায়গা খুঁজে দেয় (যেকোনো ওয়েবসাইটের মতো তোমার IP ঠিকানা ও ফোন যে ম্যাপের অংশ লোড করে, আর খোঁজা
            জায়গার নাম; &quot;আমি কোথায়&quot; চাপলে তোমার আশপাশের ম্যাপ; কোনো অ্যাকাউন্টের তথ্য নয়)।
          </li>
          <li>
            <strong>সার্ভার ও স্টোরেজ প্রদানকারী:</strong> আমাদের সার্ভার, ডাটাবেস, ছবির স্টোরেজ ও এনক্রিপ্টেড ব্যাকআপ
            চালায়।
          </li>
        </ul>
        <p>
          এরা বাংলাদেশের বাইরেও তথ্য প্রক্রিয়া করতে পারে। আমরা তোমার তথ্য বিক্রি, ভাড়া বা বিনিময় করি না এবং
          বিজ্ঞাপনদাতাদের দিই না। বাংলাদেশের আইন বা বৈধ আদালতের আদেশে প্রয়োজন হলে তথ্য দিতে পারি, এবং আইন অনুমতি দিলে
          তোমাকে জানাব।
        </p>

        <h2>কতদিন রাখা হয়</h2>
        <ul>
          <li>
            <strong>অ্যাকাউন্ট ও প্রোফাইল:</strong> তুমি মুছে না ফেলা পর্যন্ত।
          </li>
          <li>
            <strong>ক্লাস গ্রুপ:</strong> সিআর গ্রুপ মুছে না ফেলা বা শেষ সদস্য চলে না যাওয়া পর্যন্ত। এক দিনের পরিবর্তন
            তারিখের এক দিন পর আর দেখানো হয় না; ঘোষণা ৩০ দিন পর (পিন করা না থাকলে)। তোমার সদস্যপদ, লুকানো কোর্স ও
            ব্যক্তিগত ক্লাস অ্যাকাউন্টের সাথে মুছে যায়।
          </li>
          <li>
            <strong>ক্যাম্পাস ভয়েস:</strong> পোস্ট, মন্তব্য ও ছবি থাকে যতক্ষণ না লেখক মুছে ফেলে বা মডারেটর সরিয়ে দেয়।
            মুছে ফেলা ও সরানো পোস্ট সাথে সাথে সবার কাছ থেকে লুকানো হয় এবং মডারেশনের জন্য লুকানো অবস্থায় রাখা হয়।
            অ্যাকাউন্ট মুছলে বেনামি পোস্টের সাথে তোমার সংযোগ এবং তোমার ভোট, ফলো ও রিপোর্ট মুছে যায়; পোস্টগুলো তোমার
            সাথে কোনো সংযোগ ছাড়া থেকে যায়, আর যেসব পোস্টে নাম দেখানো ছিল সেখানে &quot;মুছে ফেলা অ্যাকাউন্ট&quot; দেখায়।
          </li>
          <li>
            <strong>পুশ টোকেন:</strong> সাইন আউট করলে আর ব্যবহার হয় না; অ্যাকাউন্ট মুছলে বা ফোন থেকে অ্যাপ সরানো হলে
            মুছে যায়।
          </li>
          <li>
            <strong>সাইন-ইন কোড:</strong> ১০ মিনিটে মেয়াদ শেষ, তার প্রায় এক ঘণ্টার মধ্যে মুছে ফেলা হয়।
          </li>
          <li>
            <strong>শেষ হওয়া সেশন:</strong> ৭ দিন পর মুছে ফেলা হয়।
          </li>
          <li>
            <strong>সার্ভার লগ:</strong> সর্বোচ্চ ৩০ দিন পর মুছে ফেলা হয়।
          </li>
          <li>
            <strong>ব্যাকআপ:</strong> এনক্রিপ্টেড ব্যাকআপ সর্বোচ্চ ৬ মাস রাখা হয়, তারপর মুছে ফেলা হয়। মুছে ফেলা অ্যাকাউন্ট
            ব্যাকআপ থেকে ফেরানো হয় না, শুধু পুরো সেবা বিপর্যয় থেকে উদ্ধারের প্রয়োজনে ছাড়া, এবং তখনও আবার মুছে ফেলা হয়।
          </li>
        </ul>

        <h2>তোমার অধিকার</h2>
        <ul>
          <li>
            <strong>তথ্য দেখা ও সংশোধন:</strong> প্রোফাইল ট্যাব → অ্যাকাউন্ট কার্ড ও &quot;প্রোফাইল সম্পাদনা&quot;।
          </li>
          <li>
            <strong>সব ডিভাইস থেকে সাইন আউট</strong> করা যায়।
          </li>
          <li>
            <strong>অ্যাকাউন্ট মুছে ফেলা:</strong> প্রোফাইল ট্যাব → &quot;অ্যাকাউন্ট মুছে ফেলো&quot;। সাথে সাথে স্থায়ীভাবে
            প্রোফাইল ও সব সেশন মুছে যায়। <Link href="/delete-account#bn">বিস্তারিত</Link> (ইমেইলেও অনুরোধ করা যায়)।
          </li>
          <li>
            <strong>প্রশ্ন বা অনুরোধ:</strong> <a href="mailto:hello@silifton.com">hello@silifton.com</a> ঠিকানায় লেখো।
            ৩০ দিনের মধ্যে উত্তর দেওয়া হয়।
          </li>
        </ul>

        <h2>নিরাপত্তা</h2>
        <p>
          অ্যাপ ও সার্ভারের সব যোগাযোগ এনক্রিপ্টেড (HTTPS)। সাইন-ইন কোড ও টোকেন সার্ভারে শুধু হ্যাশ রূপে থাকে। প্রতিটি
          অনুরোধে সেশন সক্রিয় কিনা যাচাই হয়, তাই সাইন আউট বা অ্যাকাউন্ট মুছলে সাথে সাথে কার্যকর হয়। কোনো তথ্য ফাঁস হলে
          আমরা দ্রুত সংশ্লিষ্টদের জানাব।
        </p>

        <h2>শিশু</h2>
        <p>
          ভার্সিটি কথা বিশ্ববিদ্যালয়ের শিক্ষার্থীদের জন্য। ১৩ বছরের কম বয়সীদের জন্য নয় এবং আমরা জেনেশুনে তাদের তথ্য
          নিই না।
        </p>

        <h2>নীতির পরিবর্তন</h2>
        <p>
          নীতি বদলালে উপরের তারিখ হালনাগাদ হবে। বড় পরিবর্তন হলে (যেমন নতুন ধরনের তথ্য বা নতুন প্রদানকারী) কার্যকর হওয়ার
          আগে অ্যাপে জানানো হবে।
        </p>

        <h2>যোগাযোগ</h2>
        <p>
          সিলিফটন · <a href="mailto:hello@silifton.com">hello@silifton.com</a> ·{" "}
          <a href="https://silifton.com">silifton.com</a>
        </p>
      </section>
    </article>
  );
}
