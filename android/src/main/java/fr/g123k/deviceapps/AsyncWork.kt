package fr.g123k.deviceapps

import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

internal class AsyncWork {
    private val threadPoolExecutor: ThreadPoolExecutor  = ThreadPoolExecutor(1,
            1, 1,
            TimeUnit.SECONDS, LinkedBlockingQueue())
    fun run(runnable: Runnable?) = threadPoolExecutor.execute(runnable)

    fun stop() = threadPoolExecutor.shutdown()
}