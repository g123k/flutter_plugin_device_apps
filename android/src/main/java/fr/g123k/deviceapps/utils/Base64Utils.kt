package fr.g123k.deviceapps.utils

import android.graphics.Bitmap
import android.graphics.Bitmap.CompressFormat
import android.util.Base64
import java.io.ByteArrayOutputStream

object Base64Utils {
    @JvmStatic
    fun encodeToBase64(image: Bitmap, compressFormat: CompressFormat?, quality: Int): String {
        val byteArrayOS = ByteArrayOutputStream()
        image.compress(compressFormat, quality, byteArrayOS)
        return Base64.encodeToString(byteArrayOS.toByteArray(), Base64.NO_WRAP)
    }
}