package com.silifton.campussaga

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
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
 *
 * Two layouts: full (class + test panel) and small (class only); Android
 * 12+ switches between them as the widget is resized.
 */
class NextClassWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, options: Bundle,
    ) {
        render(context, manager, intArrayOf(id))
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

    /** What the widget shows now, worked out once for every layout. */
    private class Content(
        val signedIn: Boolean,
        val label: String,
        val now: Boolean,
        val pill: String,
        val course: String,
        val title: String,
        val time: String,
        val room: String,
        val badge: String,
        val progress: Int, // -1 = not running
        val left: String,
        val testTitle: String,
        val testSub: String,
        val testWhen: String,
        val nextRefresh: Long,
    )

    companion object {
        private const val PREFS = "campus_widget"
        private const val KEY = "data"
        private const val ACTION_REFRESH = "com.silifton.campussaga.WIDGET_REFRESH"
        private const val MINUTE = 60_000L
        private const val DAY = 24 * 60 * MINUTE

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
            val c = content(context, now)
            for (id in ids) {
                val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    RemoteViews(
                        mapOf(
                            SizeF(150f, 50f) to small(context, c),
                            SizeF(250f, 150f) to full(context, c),
                        ),
                    )
                } else {
                    val height = manager.getAppWidgetOptions(id)
                        .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)
                    if (height < 130) small(context, c) else full(context, c)
                }
                manager.updateAppWidget(id, views)
            }
            schedule(context, maxOf(c.nextRefresh, now + MINUTE))
        }

        private fun content(context: Context, now: Long): Content {
            val data = load(context)
            var nextRefresh = startOfDay(now, 1) // midnight: "Tomorrow" becomes "Today"
            if (data == null || !data.optBoolean("signedIn", false)) {
                val text = data?.optJSONObject("labels")?.optString("signedOut")
                    ?.takeIf { it.isNotEmpty() } ?: context.getString(R.string.widget_open_app)
                return Content(
                    false, context.getString(R.string.widget_next_class), false, "", "Campus Saga",
                    text, "", "", "", -1, "", "", "", "", nextRefresh,
                )
            }
            val labels = data.getJSONObject("labels")
            val bn = data.optString("lang") == "bn"
            fun label(key: String, vararg args: Pair<String, Int>): String {
                var s = labels.optString(key)
                for ((k, v) in args) s = s.replace("{$k}", v.toString())
                return digits(s, bn)
            }

            // Next class: the first one that hasn't ended.
            val cls = firstAfter(data.optJSONArray("classes"), "end", now)
            var running = false
            var pill = ""
            var progress = -1
            var left = ""
            if (cls != null) {
                val start = cls.getLong("start")
                val end = cls.getLong("end")
                val minutes = ((start - now + MINUTE - 1) / MINUTE).toInt()
                when {
                    start <= now -> {
                        running = true
                        pill = labels.optString("now")
                        progress = (((now - start) * 100) / maxOf(end - start, 1)).toInt().coerceIn(0, 100)
                        left = label("minLeft", "m" to ((end - now + MINUTE - 1) / MINUTE).toInt())
                    }
                    minutes <= 60 -> pill = label("inMin", "m" to minutes)
                    else -> pill = dayLabel(start, now, cls.optString("date"), labels)
                }
                // Redraw when it starts or ends; every 5 minutes in the last
                // hour before it and while it runs (countdown, progress).
                nextRefresh = minOf(
                    nextRefresh,
                    when {
                        start <= now -> minOf(end, now + 5 * MINUTE)
                        start - now <= 60 * MINUTE -> minOf(start, now + 5 * MINUTE)
                        else -> start - 60 * MINUTE
                    },
                )
            }

            // Next test or deadline: the first one not yet over.
            val test = firstAfter(data.optJSONArray("tests"), "until", now)
            var testWhen = ""
            if (test != null) {
                val at = test.getLong("at")
                val days = ((startOfDay(at, 0) - startOfDay(now, 0) + DAY / 2) / DAY).toInt()
                testWhen = when {
                    days <= 0 -> labels.optString("today")
                    days == 1 -> labels.optString("tomorrow")
                    else -> label("inDays", "d" to days)
                }
                nextRefresh = minOf(nextRefresh, test.getLong("until"))
            }

            return Content(
                signedIn = true,
                label = labels.optString("nextClass"),
                now = running,
                pill = pill,
                course = cls?.optString("course") ?: labels.optString("noClass"),
                title = cls?.optString("title") ?: "",
                time = cls?.optString("time") ?: "",
                room = cls?.optString("room") ?: "",
                badge = cls?.optString("badge") ?: "",
                progress = progress,
                left = left,
                testTitle = test?.optString("title") ?: labels.optString("noTest"),
                // The chip says when; the line adds the time (or the date).
                testSub = test?.let { it.optString("time").ifEmpty { it.optString("date") } } ?: "",
                testWhen = testWhen,
                nextRefresh = nextRefresh,
            )
        }

        private fun full(context: Context, c: Content): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_next_class)
            header(context, v, c)
            v.setTextViewText(R.id.class_course, c.course)
            text(v, R.id.class_title, c.title)
            v.setViewVisibility(R.id.class_info, if (c.time.isEmpty()) View.GONE else View.VISIBLE)
            v.setTextViewText(R.id.class_time, c.time)
            v.setTextViewText(R.id.class_room, c.room)
            v.setViewVisibility(R.id.class_room_icon, if (c.room.isEmpty()) View.GONE else View.VISIBLE)
            text(v, R.id.class_badge, c.badge)
            if (c.progress >= 0) {
                v.setViewVisibility(R.id.class_progress_row, View.VISIBLE)
                v.setProgressBar(R.id.class_progress, 100, c.progress, false)
                v.setTextViewText(R.id.class_left, c.left)
            } else {
                v.setViewVisibility(R.id.class_progress_row, View.GONE)
            }
            v.setViewVisibility(R.id.test_panel, if (c.signedIn) View.VISIBLE else View.GONE)
            v.setTextViewText(R.id.test_title, c.testTitle)
            text(v, R.id.test_sub, c.testSub)
            text(v, R.id.test_when, c.testWhen)
            return v
        }

        private fun small(context: Context, c: Content): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_next_class_small)
            header(context, v, c)
            v.setTextViewText(R.id.class_course, c.course)
            text(v, R.id.class_time, listOf(c.time, c.room).filter { it.isNotEmpty() }.joinToString(" · ").ifEmpty { c.title })
            return v
        }

        private fun header(context: Context, v: RemoteViews, c: Content) {
            v.setOnClickPendingIntent(android.R.id.background, openApp(context))
            v.setTextViewText(R.id.class_label, c.label)
            // A filled pill while the class runs, a soft one otherwise.
            v.setViewVisibility(R.id.pill_now, if (c.now) View.VISIBLE else View.GONE)
            v.setTextViewText(R.id.pill_now, "● ${c.pill}")
            v.setViewVisibility(R.id.pill_soft, if (!c.now && c.pill.isNotEmpty()) View.VISIBLE else View.GONE)
            v.setTextViewText(R.id.pill_soft, c.pill)
        }

        /** Sets a text, hiding the view when it's empty. */
        private fun text(v: RemoteViews, id: Int, s: String) {
            v.setTextViewText(id, s)
            v.setViewVisibility(id, if (s.isEmpty()) View.GONE else View.VISIBLE)
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
                if (o.optLong(field) > now) return o
            }
            return null
        }

        /** "Today", "Tomorrow", or the item's own date text ("Wed 30 Oct"). */
        private fun dayLabel(at: Long, now: Long, date: String, labels: JSONObject): String = when {
            at < startOfDay(now, 1) -> labels.optString("today")
            at < startOfDay(now, 2) -> labels.optString("tomorrow")
            else -> date
        }

        private fun startOfDay(time: Long, plusDays: Int): Long = Calendar.getInstance().apply {
            timeInMillis = time
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
