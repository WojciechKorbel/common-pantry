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
                val countHeader = widgetData.getString("count_header", "All fresh!") ?: "All fresh!"
                val statusType = widgetData.getString("status_type", "fresh") ?: "fresh"
                val bodyMessage = widgetData.getString("body_message", "Everything is fresh and good to go!") ?: ""
                val footerInfo = widgetData.getString("footer_info", "") ?: ""
                val themeMode = widgetData.getString("theme_mode", "system") ?: "system"

                val nightFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                val isSystemDark = nightFlags == Configuration.UI_MODE_NIGHT_YES

                val isDark = when (themeMode) {
                    "dark" -> true
                    "light" -> false
                    else -> isSystemDark
                }

                val statusColor = when (statusType) {
                    "expired" -> if (isDark) Color.parseColor("#F87171") else Color.parseColor("#DC2626")
                    "soon" -> if (isDark) Color.parseColor("#FBBF24") else Color.parseColor("#D97706")
                    "fresh" -> if (isDark) Color.parseColor("#34D399") else Color.parseColor("#10B981")
                    else -> if (isDark) Color.parseColor("#9CA3AF") else Color.parseColor("#6B7280")
                }

                if (isDark) {
                    setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_dark)
                    setTextColor(R.id.widget_household, Color.parseColor("#F9FAFB"))
                    setTextColor(R.id.widget_message, Color.parseColor("#D1D5DB"))
                    setTextColor(R.id.widget_footer, Color.parseColor("#9CA3AF"))
                } else {
                    setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_light)
                    setTextColor(R.id.widget_household, Color.parseColor("#111827"))
                    setTextColor(R.id.widget_message, Color.parseColor("#4B5563"))
                    setTextColor(R.id.widget_footer, Color.parseColor("#6B7280"))
                }

                setTextColor(R.id.widget_count, statusColor)

                setTextViewText(R.id.widget_household, household)
                setTextViewText(R.id.widget_count, countHeader)
                setTextViewText(R.id.widget_message, bodyMessage)
                setTextViewText(R.id.widget_footer, footerInfo)

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