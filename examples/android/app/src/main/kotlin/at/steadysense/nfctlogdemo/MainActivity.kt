package at.steadysense.nfctlogdemo

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import android.nfc.tech.Ndef
import android.nfc.tech.NfcA
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import at.steadysense.nfctlog.data.NfcConfig
import at.steadysense.nfctlog.nfc.NfcHandler
import at.steadysense.nfctlog.util.LogLevel


class MainActivity : AppCompatActivity() {
    val validPatchURLs = listOf("kiwu.femsense.com", "t.steadytemp.info")

//    needed for foreground dispatch
//    private var pendingIntent: PendingIntent? = null

    private lateinit var mainUI: MainUI
    private lateinit var nfcHandler: NfcHandler
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(TAG, "onCreate called")

        super.onCreate(savedInstanceState)

        Intent(this, javaClass).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
//     needed for foreground dispatch
//        pendingIntent = PendingIntent.getActivity(this, 0, intent, getPendingIntentFlags(isMutable = true))

        val config = NfcConfig(
            logLevel = LogLevel.DEBUG,
            showUi = true,
            validUrls = validPatchURLs
        )
        nfcHandler = NfcHandler(this, config)

        mainUI = MainUI(this, nfcHandler)
        mainUI.onCreate()
    }

    override fun onResume() {
        Log.i(TAG, "onResume called")
        super.onResume()
        //nfcHandler.onResume()
        arrayOf(IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED).apply {
            addDataScheme("https")
            validPatchURLs.forEach { addDataAuthority(it, null) }
        })
        arrayOf(arrayOf(Ndef::class.java.name, NfcA::class.java.name))
//    needed for foreground dispatch
//        NfcAdapter.getDefaultAdapter(this).enableForegroundDispatch(this, pendingIntent, intentFiltersArray, techListsArray)

        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return

        val flags = NfcAdapter.FLAG_READER_NFC_A or
                NfcAdapter.FLAG_READER_NFC_B or
                NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or
                NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

        adapter.enableReaderMode(this, NfcAdapter.ReaderCallback { tag ->
            nfcHandler?.onTagDiscovered(tag)
        }, flags, null)
    }

    public override fun onPause() {
        Log.i(TAG, "onPause called")
        super.onPause()
        nfcHandler.onPause()
//    needed for foreground dispatch
//        NfcAdapter.getDefaultAdapter(this).disableForegroundDispatch(this)
    }

    override fun onNewIntent(intent: Intent) {
        Log.i(TAG, "onNewIntent called")
        super.onNewIntent(intent)
//    needed for foreground dispatch
//        nfcHandler.onNewIntent(intent)
    }

    //    needed for foreground dispatch
    private fun getPendingIntentFlags(isMutable: Boolean = false) =
        when {
            isMutable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE

            !isMutable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            else -> PendingIntent.FLAG_UPDATE_CURRENT
        }

    internal fun isNfcEnabled(): Boolean {
        val a = NfcAdapter.getDefaultAdapter(this)
        return a != null && a.isEnabled
    }


    internal fun isNfcAvailable(): Boolean {
        return NfcAdapter.getDefaultAdapter(this) != null
    }

}
