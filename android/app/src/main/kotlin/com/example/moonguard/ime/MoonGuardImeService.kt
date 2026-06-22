package com.example.moonguard.ime

import android.inputmethodservice.InputMethodService
import android.view.View
import com.example.moonguard.R

/**
 * Custom IME stub. System-wide keyword filtering only applies when the user selects
 * this keyboard; implement [InputConnection] handling to filter text (or pull rules
 * from local storage synced from Supabase).
 */
class MoonGuardImeService : InputMethodService() {
    override fun onCreateInputView(): View {
        return layoutInflater.inflate(R.layout.keyboard_stub, null)
    }
}
