package com.kotexi.kovisor

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setImmersiveMode()
        enterKioskMode()
    }

    override fun onResume() {
        super.onResume()
        setImmersiveMode() // <-- Reaplicar el modo inmersivo por si el sistema lo restablece
    }

    private fun setImmersiveMode() {
        window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                )
    }

    private fun enterKioskMode() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(packageName)) {
            val packages = arrayOf(packageName)
            dpm.setLockTaskPackages(adminComponent, packages)
            dpm.setKeyguardDisabledFeatures(
                adminComponent,
                0x00000004 // KEYGUARD_DISABLE_EXPAND_NOTIFICATIONS
            )
            Toast.makeText(this, "Políticas de seguridad aplicadas", Toast.LENGTH_SHORT).show()
        }

        if (dpm.isLockTaskPermitted(packageName)) {
            startLockTask()
            Toast.makeText(this, "Modo Kiosko activado", Toast.LENGTH_LONG).show()
        } else {
            Toast.makeText(this, "No se pudo entrar en modo Kiosko. La app no es Device Owner o Lock Task no está permitido.", Toast.LENGTH_LONG).show()
        }
    }

    fun exitKioskMode() {
        stopLockTask()
        Toast.makeText(this, "Saliendo de modo Kiosko", Toast.LENGTH_SHORT).show()

        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)
        dpm.setKeyguardDisabledFeatures(
            adminComponent,
            0x00000000 // KEYGUARD_FEATURES_NONE
        )
    }

    override fun onBackPressed() {
        Toast.makeText(this, "El botón de retroceso está deshabilitado en modo Kiosko", Toast.LENGTH_SHORT).show()
    }

    /*
    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        if (event?.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event?.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }
    */
}
