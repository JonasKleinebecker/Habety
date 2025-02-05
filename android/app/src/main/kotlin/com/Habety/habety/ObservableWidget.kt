package com.Habety.habety

import HomeWidgetGlanceWidgetReceiver

class ObservableWidget : HomeWidgetGlanceWidgetReceiver<ObservableAppWidget>() {
  override val glanceAppWidget: ObservableAppWidget
    get() = ObservableAppWidget()
}
