/*
 * Created by Ilan Rasekh on 2019/9/27
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

package dev.pseudorand.nullpass

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.RequiresApi
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  //
  /*
  @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    flutterView.setSecure(true)
    this.window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
  }
  // */
  // /*
   @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterView.setSecure(true)
    this.window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
  }
  // */
}
