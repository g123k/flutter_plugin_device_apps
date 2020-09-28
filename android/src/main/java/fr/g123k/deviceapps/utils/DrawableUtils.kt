package fr.g123k.deviceapps.utils

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable

object DrawableUtils {
    @JvmStatic
    fun getBitmapFromDrawable(drawable: Drawable): Bitmap {
        val bmp = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bmp
    }
}