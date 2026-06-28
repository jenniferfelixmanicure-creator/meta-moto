package com.metamoto.meta_moto

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MetaMotoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "MetaMotoWidget"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val ganhoHoje = prefs.getFloat("ganho_hoje", 0f).toDouble()
            val metaDiaria = prefs.getFloat("meta_diaria", 0f).toDouble()
            val corridasHoje = prefs.getInt("corridas_hoje", 0)
            val rph = prefs.getFloat("rph", 0f).toDouble()

            val fmt = NumberFormat.getCurrencyInstance(Locale("pt", "BR"))
            val ganhoStr = fmt.format(ganhoHoje)

            val progressoPct = if (metaDiaria > 0)
                ((ganhoHoje / metaDiaria) * 100).toInt().coerceIn(0, 100)
            else 0

            val dateStr = SimpleDateFormat("EEE, d MMM", Locale("pt", "BR"))
                .format(Date())
                .replaceFirstChar { it.uppercase() }

            val corridasStr = "$corridasHoje corrida${if (corridasHoje != 1) "s" else ""}"
            val rphStr = if (rph > 0) fmt.format(rph) + "/h" else ""

            val views = RemoteViews(context.packageName, R.layout.widget_meta_moto)
            views.setTextViewText(R.id.widget_ganho_hoje, ganhoStr)
            views.setTextViewText(R.id.widget_meta_pct, "$progressoPct%")
            views.setProgressBar(R.id.widget_progress, 100, progressoPct, false)
            views.setTextViewText(R.id.widget_corridas, corridasStr)
            views.setTextViewText(R.id.widget_date, dateStr)
            views.setTextViewText(R.id.widget_rph, rphStr)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAll(context: Context, data: Map<String, Any>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()

            (data["ganho_hoje"] as? Double)?.let {
                editor.putFloat("ganho_hoje", it.toFloat())
            }
            (data["meta_diaria"] as? Double)?.let {
                editor.putFloat("meta_diaria", it.toFloat())
            }
            (data["corridas_hoje"] as? Int)?.let {
                editor.putInt("corridas_hoje", it)
            }
            (data["rph"] as? Double)?.let {
                editor.putFloat("rph", it.toFloat())
            }
            editor.apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, MetaMotoWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }
    }
}
