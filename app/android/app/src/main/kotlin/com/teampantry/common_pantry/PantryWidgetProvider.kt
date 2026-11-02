package com.teampantry.common_pantry

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PantryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pantry_widget).apply {
                val household = widgetData.getString("household_name", "My Pantry") ?: "My Pantry"
                val count = widgetData.getInt("expiring_count", 0)
                val headline = widgetData.getString("headline", "Everything is fresh!") ?: "Everything is fresh!"
                val themeMode = widgetData.getString("theme_mode", "system") ?: "system"

                val isDark = when (themeMode) {
                    "dark" -> true
                    "light" -> false
                    else -> {
                        val nightFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                        nightFlags == Configuration.UI_MODE_NIGHT_YES
                    }
                }

                setInt(
                    R.id.widget_container,
                    "setBackgroundResource",
                    if (isDark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
                )

                val titleColor = if (isDark) Color.parseColor("#F9FAFB") else Color.parseColor("#1F2937")
                val subtitleColor = if (isDark) Color.parseColor("#9CA3AF") else Color.parseColor("#6B7280")
                val alertColor = if (isDark) Color.parseColor("#F87171") else Color.parseColor("#DC2626")

                setTextColor(R.id.widget_household, titleColor)
                setTextColor(R.id.widget_message, subtitleColor)
                setTextColor(R.id.widget_count, alertColor)

                setTextViewText(R.id.widget_household, household)
                setTextViewText(
                    R.id.widget_count,
                    if (count > 0) "$count expiring soon" else "All fresh!"
                )
                setTextViewText(R.id.widget_message, headline)

                val openIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingOpen = PendingIntent.getActivity(
                    context,
                    0,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingOpen)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}