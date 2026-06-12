package at.steadysense.nfctlogdemo

import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.util.Log
import android.view.View.VISIBLE
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.widget.SwitchCompat
import androidx.core.content.ContextCompat.getSystemService
import androidx.core.widget.addTextChangedListener
import androidx.lifecycle.lifecycleScope
import at.steadysense.nfctlog.data.TlogRecord
import at.steadysense.nfctlog.nfc.NfcHandler
import at.steadysense.nfctlog.util.ImmutableByteArray
import com.google.android.material.slider.RangeSlider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.Locale
import kotlin.math.roundToInt


fun getCurrentLocale(context: Context): Locale {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        context.resources.configuration.locales[0]
    } else {
        context.resources.configuration.locale
    }
}

class MainUI(val ac: MainActivity, val nfcHandler: NfcHandler) {

    /**
     * In a production app, we should not "store" the Activity state in a TextView.
     * Instead, use something like ViewModel to persist the state during Activity recreations (e.g. screen rotations).
     */
    private lateinit var mainTextView: TextView
    private lateinit var readButton: Button
    private lateinit var readOrActivateButton: Button
    private lateinit var activateButton: Button
    private lateinit var resetButton: Button
    private lateinit var intervalSlider: RangeSlider
    private lateinit var intervalMinutesTextView: TextView
    private lateinit var lockSwitch: SwitchCompat
    private lateinit var ringbufferSwitch: SwitchCompat
    private lateinit var uvloSwitch: SwitchCompat
    private lateinit var statusBar: TextView
    private lateinit var activationConfigContainer: LinearLayout
    private lateinit var userDataTextInput: TextView

    var activationConfig: UiActivationConfig? = null

    fun onCreate() {
        ac.setContentView(R.layout.activity_main)

        mainTextView = ac.findViewById(R.id.main_text_view)
        readButton = ac.findViewById(R.id.readButton)
        readOrActivateButton = ac.findViewById(R.id.readOrActivateButton)
        activateButton = ac.findViewById(R.id.activateButton)
        statusBar = ac.findViewById(R.id.status_bottom_bar)
        resetButton = ac.findViewById(R.id.resetButton)
        lockSwitch = ac.findViewById(R.id.lockSwitch)
        ringbufferSwitch = ac.findViewById(R.id.ringbufferSwitch)
        uvloSwitch = ac.findViewById(R.id.uvloSwitch)
        intervalSlider = ac.findViewById(R.id.intervalSlider)
        userDataTextInput = ac.findViewById(R.id.userDataEditText)
        activationConfigContainer = ac.findViewById(R.id.activationConfigContainer)
        activationConfigContainer.visibility = VISIBLE

        intervalSlider.setLabelFormatter { value ->
            when (value.roundToInt()) {
                0 -> "1 sec (DO NOT USE IN PRODUCTION)"
                1 -> "30 sec"
                2 -> "1 min"
                3 -> "5 min"
                4 -> "10 min"
                5 -> "15 min"
                6 -> "30 min"
                7 -> "1 hour"
                else -> "Unknown"
            }
        }

        activationConfig = UiActivationConfig(
            ac = ac,
            intervalSeconds = intervalSlider.values[0],
            enableRingBuffer = ringbufferSwitch.isChecked,
            enableUVLO = uvloSwitch.isChecked,
            lock = lockSwitch.isChecked,
            userData = ImmutableByteArray.fromASCIIPadded(userDataTextInput.text.toString())
        )

        intervalSlider.values = arrayOf(3f).toMutableList()
        activationConfig?.onValueChange(intervalSlider, 3f, false)

        intervalSlider.addOnChangeListener(activationConfig!!)
        userDataTextInput.addTextChangedListener { editable ->
            val text = editable?.toString() ?: "" // Handle null editable
            activationConfig?.userData =
                ImmutableByteArray.fromASCIIPadded(text) // Use fromASCII for padding
        }
        readOrActivateButton.setOnClickListener {
            nfcHandler.readOrActivate(activationConfig!!.build()) { patchData, error ->
                this.ac.lifecycleScope.launch {
                    withContext(Dispatchers.Main) {
                        if (patchData != null) {
                            onReadSuccess(patchData.record)
                            val jsonPatchData = Json.encodeToString(patchData)
                            println(jsonPatchData)
                        }
                        if (error != null) {
                            Log.e("MainUi", "Read failed", error)
                        }
                    }
                }
            }
        }
        readButton.setOnClickListener {
            nfcHandler.read { patchData, error ->
                this.ac.lifecycleScope.launch {
                    withContext(Dispatchers.Main) {
                        if (patchData != null) {
                            onReadSuccess(patchData.record)
                            val jsonPatchData = Json.encodeToString(patchData)
                            println(jsonPatchData)
                        }
                        if (error != null) {
                            Log.e("MainUi", "Read failed", error)
                        }
                    }
                }
            }
        }
        activateButton.setOnClickListener {
            nfcHandler.activate(activationConfig!!.build()) { patchData, error ->
                this.ac.lifecycleScope.launch {
                    withContext(Dispatchers.Main) {
                        if (patchData != null) {
                            Log.i("MainUI", "Activation successful")
                            onPatchActivated(patchData.record)
                        } else if (error != null) {
                            onPatchActivationFailure(error)
                            Log.e("MainUI", "Activation failed", error)
                        }
                    }
                }
            }
        }
        resetButton.setOnClickListener {
            nfcHandler.reset { patchData, error ->
                this.ac.lifecycleScope.launch {
                    withContext(Dispatchers.Main) {
                        if (patchData != null) {
                            Log.i("MainUI", "Reset successful")
                            resetSuccessfull(patchData.record)
                        } else if (error != null) {
                            Log.e("MainUI", "Reset failed", error)
                            resetFailed(error)
                        }
                    }
                }
            }
        }
        lockSwitch.setOnCheckedChangeListener(activationConfig)
        ringbufferSwitch.setOnCheckedChangeListener(activationConfig)
        uvloSwitch.setOnCheckedChangeListener(activationConfig)
        setMainText(ac.getString(R.string.nfc_available_launch_text), largeText = true)
        showNfcAvailableUI()
    }

    private fun showNfcAvailableUI() {
        // The onResume()-logic is broken for the sake of brevity.
        val available = nfcHandler.isNfcAvailable
        val enabled = nfcHandler.isNfcEnabled
        if (!available) {
            setMainText(ac.getString(R.string.nfc_not_available), largeText = true)
        } else if (!enabled) {
            setMainText(ac.getString(R.string.nfc_can_be_activated), largeText = true)
            showNfcEnableDialog()
        }
    }

    fun onReadSuccess(tlogRecord: TlogRecord) {
        showPatchInfos(tlogRecord, statusMessage = null)
        statusBar.setBackgroundColor(ac.getColor(R.color.colorPrimary))
        statusBar.text = "Read sucessfull"
        activationConfig
    }

    fun onPatchActivated(record: TlogRecord) {
        showPatchInfos(record, ac.getString(R.string.on_patch_activated))
        statusBar.setBackgroundColor(ac.getColor(R.color.colorPrimary))
        statusBar.text = "Activation successful"
    }

    fun onPatchActivationFailure(error: Throwable) {
        showError(error, ac.getString(R.string.on_patch_activation_failure))
        statusBar.setBackgroundColor(ac.getColor(R.color.colorAccent))
        statusBar.text = "Activation Failed"
    }

    fun resetSuccessfull(record: TlogRecord) {
        showPatchInfos(record, statusMessage = null)
        statusBar.setBackgroundColor(ac.getColor(R.color.colorPrimary))
        statusBar.text = "Reset successfull"
    }

    fun resetFailed(error: Throwable) {
        showError(error, "Patch reset failed")
        statusBar.setBackgroundColor(ac.getColor(R.color.colorAccent))
        statusBar.text = "Reset Failed"
    }

    private fun showPatchInfos(tlogRecord: TlogRecord?, statusMessage: String?) {
        val sb = StringBuilder()
        if (statusMessage != null) {
            sb.appendLine(statusMessage)
            sb.appendLine()
        }
        if (tlogRecord != null) {
            sb.append(tlogRecord.format())
            tlogRecord.temperatures.forEach {
                val s = String.format(
                    Locale.US,
                    "%3d: %5.2f° %s",
                    it.index,
                    it.temperature,
                    if (it.valid) "" else "invalid!"
                )
                sb.appendLine(s)
            }

        }
        setMainText(sb.toString(), largeText = false)
    }

    private fun showError(error: Throwable?, statusMessage: String?) {
        val sb = StringBuilder()
        if (statusMessage != null) {
            sb.appendLine(statusMessage)
            sb.appendLine()
        }
        if (error != null) {
            sb.append(error.stackTraceToString())
        }
        setMainText(sb.toString(), largeText = false)
    }

    private fun setMainText(s: String, largeText: Boolean) {
        mainTextView.text = s
        if (largeText) {
            mainTextView.setTypeface(null, Typeface.BOLD)
            mainTextView.textSize = 23.toFloat()
        } else {
            mainTextView.setTypeface(null, Typeface.NORMAL)
            mainTextView.textSize = 18.toFloat()
        }
    }

    private fun vibratePhone() {
        val VIBRATE_DURATION = 500.toLong()
        val v = getSystemService(ac, Vibrator::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v?.vibrate(
                VibrationEffect.createOneShot(VIBRATE_DURATION, VibrationEffect.DEFAULT_AMPLITUDE)
            )
        } else {
            //deprecated in API 26
            v?.vibrate(VIBRATE_DURATION)
        }
    }

    private fun showNfcEnableDialog() {
        val dialog = AlertDialog.Builder(ac)
            .setTitle(R.string.nfc_disabled)
            .setMessage(R.string.nfc_can_be_activated)
            .setPositiveButton(R.string.open_settings) { _, _ ->
                try {
                    ac.startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                } catch (e: Throwable) {
                    Log.e(MainUI::class.java.simpleName, "intent launch exception", e)
                }
            }
            .setNeutralButton(android.R.string.cancel) { dialog, _ ->
                dialog.dismiss()
            }
            .setCancelable(false)
            .create()
        dialog.setCanceledOnTouchOutside(false)
        dialog.show()
    }
}
