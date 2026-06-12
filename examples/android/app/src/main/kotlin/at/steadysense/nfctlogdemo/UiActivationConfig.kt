package at.steadysense.nfctlogdemo

import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.widget.CompoundButton
import at.steadysense.nfctlog.data.ActivationConfig
import at.steadysense.nfctlog.util.ImmutableByteArray
import com.google.android.material.slider.RangeSlider
import kotlin.math.roundToInt


private const val TAG = "UiActivationConfig"

class UiActivationConfig(
    var ac: MainActivity,
    var intervalSeconds: Float,
    var lock: Boolean,
    var enableRingBuffer: Boolean,
    var enableUVLO: Boolean,
    var userData: ImmutableByteArray,
) : RangeSlider.OnChangeListener,
    CompoundButton.OnCheckedChangeListener,
    TextWatcher {

    override fun onCheckedChanged(buttonView: CompoundButton?, isChecked: Boolean) {
        when (buttonView?.id) {
            R.id.lockSwitch -> {
                Log.i(TAG, "UI: Lock changed to $isChecked")
                lock = isChecked
            }

            R.id.ringbufferSwitch -> {
                Log.i(TAG, "UI: Ringbuffer changed to $isChecked")
                enableRingBuffer = isChecked
            }

            R.id.uvloSwitch -> {
                Log.i(TAG, "UI: UVLO changed to $isChecked")
                enableUVLO = isChecked
            }
        }
    }

    override fun onValueChange(p0: RangeSlider, p1: Float, p2: Boolean) {
        intervalSeconds = when (p1.roundToInt()) {
            0 -> 1f
            1 -> 30f
            2 -> 60f
            3 -> 300f
            4 -> 600f
            5 -> 900f
            6 -> 1800f
            7 -> 3600f
            else -> 5f
        }
        Log.i(TAG, "UI: Measurement Interval changed to $intervalSeconds")

    }


    override fun afterTextChanged(p0: Editable?) {
    }

    override fun beforeTextChanged(p0: CharSequence?, start: Int, count: Int, after: Int) {
    }

    override fun onTextChanged(p0: CharSequence?, start: Int, before: Int, count: Int) {

        if (p0 == null)
            return
        userData = ImmutableByteArray.fromASCII(p0.toString())
    }

    fun build(): ActivationConfig {
        return ActivationConfig(
            intervalSeconds.toInt(),
            enableRingBuffer = enableRingBuffer,
            enableUVLO = enableUVLO,
            lock = lock,
            userData
        )
    }
}
