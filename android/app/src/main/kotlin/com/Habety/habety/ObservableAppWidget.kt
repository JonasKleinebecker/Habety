package com.Habety.habety

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class HabitNative(
        val id: String,
        val name: String,
        val color: Int, // Stored as an integer
        val maxMissedDays: Int,
        val completedDays: Map<Date, Int>,
)

class ObservableAppWidget : GlanceAppWidget() {

  override val stateDefinition: GlanceStateDefinition<*>?
    get() = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { GlanceContent(context, currentState()) }
  }

  fun parseHabitFromJson(habitJsonStr: String): HabitNative? {
    try {
      val habitJson = JSONObject(habitJsonStr)
      val id = habitJson.getString("id")
      val name = habitJson.getString("name")
      val color = habitJson.getInt("color")
      val maxMissedDays = habitJson.optInt("maxMissedDays", 0)

      // Parse the completedDates map
      val completedDaysMap = mutableMapOf<Date, Int>()
      val completedDatesJson = habitJson.optJSONObject("completedDates")
      if (completedDatesJson != null) {
        // Define a formatter matching the ISO8601 format you used.
        // Here we assume the date string is formatted as "yyyy-MM-dd'T'HH:mm:ss.SSS"
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
        // Set the formatter to UTC if your Dart dates were in UTC
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")
        val keys = completedDatesJson.keys()
        while (keys.hasNext()) {
          val dateKey = keys.next() // e.g. "2023-02-05T00:00:00.000"
          val value = completedDatesJson.optInt(dateKey, 0)
          try {
            val date = dateFormat.parse(dateKey)
            if (date != null) {
              completedDaysMap[date] = value
            }
          } catch (e: Exception) {
            e.printStackTrace()
          }
        }
      }

      return HabitNative(
              id = id,
              name = name,
              color = color,
              maxMissedDays = maxMissedDays,
              completedDays = completedDaysMap
      )
    } catch (e: JSONException) {
      e.printStackTrace()
    }
    return null
  }

  @Composable
  private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val habitsJson = prefs.getString("habits", null)

    val habits = mutableListOf<HabitNative>()
    if (habitsJson != null) {
      try {
        val habitsArray = JSONArray(habitsJson)
        for (i in 0 until habitsArray.length()) {
          val habitJsonStr = habitsArray.getString(i)
          val habit = parseHabitFromJson(habitJsonStr)
          habits.add(habit!!)
        }
      } catch (e: JSONException) {
        e.printStackTrace()
      }
    }

    Box(modifier = GlanceModifier.background(Color.White)) {
      Column { Text(text = habits[0].completedDays.toString()) }
    }
  }
}
