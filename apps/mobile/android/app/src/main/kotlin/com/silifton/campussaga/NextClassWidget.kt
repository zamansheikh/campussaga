package com.silifton.campussaga

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget: the next class and the next test or deadline.
 *
 * The app saves the next two weeks of classes and tests, with their texts
 * already in the app's language ([save], from the "campussaga/widget"
 * channel in MainActivity). The widget picks what is next by the phone's
 * clock, so it stays right while the app is closed, and asks to be redrawn
 * at the next moment that changes what it shows (a class starting or
 * ending, midnight). Those alarms don't wake the phone.
 */
class NextClassWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REFRESH, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> refresh(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        alarmManager(context).cancel(refreshIntent(context))
    }

    companion object {
        private const val PREFS = "campus_widget"
        private const val KEY = "data"
        private const val ACTION_REFRESH = "com.silifton.campussaga.WIDGET_REFRESH"
        private const val MINUTE = 60_000L

        /** Stores the app's data and redraws every widget. */
        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NextClassWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val now = System.currentTimeMillis()
            val data = load(context)
            val views = RemoteViews(context.packageName, R.layout.widget_next_class)
            views.setOnClickPendingIntent(R.id.widget_root, openApp(context))
            var nextRefresh = startOfDay(now, 1) // midnight: "Tomorrow" becomes "Today"

            if (data == null || !data.optBoolean("signedIn", false)) {
                views.setTextViewText(R.id.class_when, "")
                views.setTextViewText(R.id.class_course, "Campus Saga")
                views.setTextViewText(
                    R.id.class_line,
                    data?.optJSONObject("labels")?.optString("signedOut")
                        ?: context.getString(R.string.widget_open_app),
                )
                views.setViewVisibility(R.id.divider, View.GONE)
                views.setViewVisibility(R.id.test_row, View.GONE)
            } else {
                val labels = data.getJSONObject("labels")
                val bn = data.optString("lang") == "bn"
                views.setTextViewText(R.id.class_label, labels.optString("nextClass"))
                views.setTextViewText(R.id.test_label, labels.optString("nextTest"))
                views.setViewVisibility(R.id.divider, View.VISIBLE)
                views.setViewVisibility(R.id.test_row, View.VISIBLE)

                // Next class: the first one that hasn't ended.
                val cls = firstAfter(data.optJSONArray("classes"), "end", now)
                if (cls == null) {
                    views.setTextViewText(R.id.class_when, "")
                    views.setTextViewText(R.id.class_course, labels.optString("noClass"))
                    views.setTextViewText(R.id.class_line, "")
                } else {
                    val start = cls.getLong("start")
                    val end = cls.getLong("end")
                    val minutes = ((start - now + MINUTE - 1) / MINUTE).toInt()
                    val whenText = when {
                        start <= now -> labels.optString("now")
                        minutes <= 60 -> digits(labels.optString("inMin").replace("{m}", minutes.toString()), bn)
                        else -> dayLabel(start, now, cls.optString("date"), labels)
                    }
                    views.setTextViewText(R.id.class_when, whenText)
                    val badge = cls.optString("badge")
                    val course = cls.optString("course")
                    views.setTextViewText(R.id.class_course, if (badge.isEmpty()) course else "$course · $badge")
                    views.setTextViewText(R.id.class_line, cls.optString("line"))
                    // Redraw when it starts or ends; every 5 minutes in the last
                    // hour before it and while it runs (the countdown).
                    nextRefresh = minOf(
                        nextRefresh,
                        when {
                            start <= now -> minOf(end, now + 5 * MINUTE)
                            start - now <= 60 * MINUTE -> minOf(start, now + 5 * MINUTE)
                            else -> start - 60 * MINUTE
                        },
                    )
                }

                // Next test or deadline: the first one not yet past.
                val test = firstAfter(data.optJSONArray("tests"), "until", now)
                if (test == null) {
                    views.setTextViewText(R.id.test_text, labels.optString("noTest"))
                } else {
                    val day = dayLabel(test.getLong("at"), now, test.optString("date"), labels)
                    views.setTextViewText(R.id.test_text, listOf(test.optString("title"), day, test.optString("time"))
                        .filter { it.isNotEmpty() }.joinToString(" · "))
                    nextRefresh = minOf(nextRefresh, test.getLong("until"))
                }
            }

            manager.updateAppWidget(ids, views)
            schedule(context, maxOf(nextRefresh, now + MINUTE))
        }

        private fun load(context: Context): JSONObject? = try {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)?.let { JSONObject(it) }
        } catch (e: Exception) {
            null
        }

        private fun firstAfter(items: JSONArray?, field: String, now: Long): JSONObject? {
            if (items == null) return null
            for (i in 0 until items.length()) {
                val o = items.getJSONObject(i)
                if (o.getLong(field) > now) return o
            }
            return null
        }

        /** "Today", "Tomorrow", or the item's own date text ("Wed 30 Oct"). */
        private fun dayLabel(at: Long, now: Long, date: String, labels: JSONObject): String = when {
            at < startOfDay(now, 1) -> labels.optString("today")
            at < startOfDay(now, 2) -> labels.optString("tomorrow")
            else -> date
        }

        private fun startOfDay(now: Long, plusDays: Int): Long = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_MONTH, plusDays)
        }.timeInMillis

        /** Bangla digits in Bangla. */
        private fun digits(s: String, bn: Boolean): String =
            if (!bn) s else s.map { if (it in '0'..'9') '০' + (it - '0') else it }.joinToString("")

        private fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context, 1,
            Intent(context, NextClassWidget::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun alarmManager(context: Context) =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        /** A non-waking alarm: delivered when the phone is next awake. */
        private fun schedule(context: Context, at: Long) {
            alarmManager(context).set(AlarmManager.RTC, at, refreshIntent(context))
        }
    }
}
