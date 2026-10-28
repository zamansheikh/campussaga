// Text for the Google Play graphics and video, in English and Bangla.
// Each screenshot names the raw app screen(s) it shows (rendered by
// apps/mobile/tool/screenshots/store_test.dart) and its caption.

export const languages = {
  en: {
    playLocale: 'en-US',
    tagline: 'Your class routine and campus voice',
    subTagline: 'For university students in Bangladesh',
    outro: 'Free on Google Play',
    voice: {
      // ElevenLabs voice and narration (tool/store/voice.mjs).
      id: 'cgSgspJ2msm6clMCkdW9', // Jessica
      intro: 'Varsity Kotha. Your class routine and your campus voice, in one app.',
      outro: 'Varsity Kotha! Get it free, on Google Play.',
    },
    shots: [
      {
        screens: ['01-today'],
        chip: 'Today',
        title: 'Your day,\nat a glance',
        body: 'Next class, room and teacher, with a live countdown.',
        say: 'Open it in the morning, and see your next class, room and teacher.'
      },
      {
        screens: ['02-routine'],
        chip: 'Routine',
        title: 'Your whole week,\nalways up to date',
        body: 'One shared routine for your section. When the CR changes it, everyone sees it.',
        say: 'One routine for your whole section, always up to date.'
      },
      {
        screens: ['04-group'],
        chip: 'Class changes',
        title: 'Class moved?\nYou’ll know first',
        body: 'Cancelled, rescheduled or moved to another day: one tap from your CR, a notification to everyone.',
        say: 'Class cancelled, or moved to another day? You’ll be the first to know.'
      },
      {
        screens: ['03-today-tests'],
        chip: 'Tests & deadlines',
        title: 'Never miss a quiz\nor a deadline',
        body: 'Class tests, assignments and exams, with a reminder the evening before.',
        say: 'Reminders for tests and deadlines, the evening before.'
      },
      {
        screens: ['05-voice'],
        chip: 'Campus Voice',
        title: 'Raise campus\nproblems, safely',
        body: 'Post anonymously. Others add “Me too”, so the biggest problems rise to the top.',
        say: 'Raise any campus problem, without giving your name.'
      },
      {
        screens: ['06-issue-reply'],
        chip: 'Real answers',
        title: 'Hear back from\nyour university',
        body: 'Officials reply in the open, and you follow every step until it’s solved.',
        say: 'And get answers straight from your university.'
      },
      {
        screens: ['07-find'],
        chip: 'Find your class',
        title: 'Join your section\nin seconds',
        body: 'Search your university’s routines, or add only the courses you take.',
        say: 'Find your section in seconds.'
      },
      {
        screens: ['08-bus', '08-cgpa'],
        chip: 'Bus routes & CGPA',
        title: 'Bus times and CGPA,\nin the same app',
        body: 'The next bus from your stop, and a CGPA planner on the UGC scale.',
        say: 'Bus times, your CGPA… it’s all here.'
      },
    ],
  },
  bn: {
    playLocale: 'bn-BD',
    tagline: 'তোমার ক্লাস রুটিন আর ক্যাম্পাসের কণ্ঠ',
    subTagline: 'বাংলাদেশের বিশ্ববিদ্যালয় শিক্ষার্থীদের জন্য',
    outro: 'গুগল প্লেতে ফ্রি',
    voice: {
      id: 'yBrGXLW1RaXDUjUf3kQi', // Tazim, native Bangladeshi accent
      intro: 'ভার্সিটি কথা। তোমার ক্লাস রুটিন আর ক্যাম্পাসের কথা, এক অ্যাপে।',
      outro: 'ভার্সিটি কথা। আজই নামিয়ে নাও, গুগল প্লে থেকে।',
    },
    shots: [
      {
        screens: ['01-today'],
        chip: 'আজ',
        title: 'এক নজরে\nতোমার পুরো দিন',
        body: 'পরের ক্লাস, রুম আর শিক্ষক, সাথে লাইভ কাউন্টডাউন।',
        say: 'সকালে অ্যাপটা খুললেই দেখবে পরের ক্লাস, রুম আর টিচার।'
      },
      {
        screens: ['02-routine'],
        chip: 'রুটিন',
        title: 'পুরো সপ্তাহের রুটিন,\nসবসময় আপডেট',
        body: 'পুরো সেকশনের জন্য একটাই রুটিন। সিআর বদলালে সবাই সাথে সাথে দেখে।',
        say: 'পুরো সেকশনের জন্য একটাই রুটিন, সবসময় আপডেটেড।'
      },
      {
        screens: ['04-group'],
        chip: 'ক্লাস পরিবর্তন',
        title: 'ক্লাস বদলালে\nসবার আগে তুমি জানবে',
        body: 'বাতিল, সময় বদল বা অন্য দিনে সরানো: সিআর-এর এক ট্যাপে সবার ফোনে নোটিফিকেশন।',
        say: 'ক্লাস ক্যানসেল হলো, বা অন্য দিনে গেল? সবার আগে তুমিই জানবে।'
      },
      {
        screens: ['03-today-tests'],
        chip: 'পরীক্ষা ও ডেডলাইন',
        title: 'কুইজ বা ডেডলাইন\nআর মিস নয়',
        body: 'ক্লাস টেস্ট, অ্যাসাইনমেন্ট আর পরীক্ষা, আগের সন্ধ্যায় রিমাইন্ডার।',
        say: 'ক্লাস টেস্ট আর অ্যাসাইনমেন্টের রিমাইন্ডার, আগের সন্ধ্যাতেই।'
      },
      {
        screens: ['05-voice'],
        chip: 'ক্যাম্পাস ভয়েস',
        title: 'ক্যাম্পাসের সমস্যা\nতোলো নিরাপদে',
        body: 'বেনামে পোস্ট করো। অন্যরা “আমারও” দিলে বড় সমস্যাগুলো উপরে উঠে আসে।',
        say: 'ক্যাম্পাসের যেকোনো সমস্যা তুলে ধরো, নাম না জানিয়েই।'
      },
      {
        screens: ['06-issue-reply'],
        chip: 'আসল উত্তর',
        title: 'বিশ্ববিদ্যালয়ের কাছ থেকে\nউত্তর পাও',
        body: 'কর্তৃপক্ষ সবার সামনে উত্তর দেয়, সমাধান পর্যন্ত প্রতিটা ধাপ দেখতে পাও।',
        say: 'আর উত্তর পাও সরাসরি বিশ্ববিদ্যালয়ের কাছ থেকে।'
      },
      {
        screens: ['07-find'],
        chip: 'ক্লাস খুঁজে নাও',
        title: 'সেকেন্ডেই তোমার\nসেকশনে যোগ দাও',
        body: 'বিশ্ববিদ্যালয়ের রুটিন খোঁজো, বা শুধু তোমার কোর্সগুলো যোগ করো।',
        say: 'নিজের সেকশন খুঁজে নাও, মাত্র কয়েক সেকেন্ডে।'
      },
      {
        screens: ['08-bus', '08-cgpa'],
        chip: 'বাস ও সিজিপিএ',
        title: 'বাসের সময় আর সিজিপিএ,\nএক অ্যাপেই',
        body: 'তোমার স্টপ থেকে পরের বাস, আর ইউজিসি স্কেলে সিজিপিএ হিসাব।',
        say: 'বাসের সময়, সিজিপিএ হিসাব… সবই এখানে।'
      },
    ],
  },
};
