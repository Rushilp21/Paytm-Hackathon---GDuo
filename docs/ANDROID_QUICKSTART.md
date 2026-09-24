# Run FINPATH on Android

## 1. Open the project

Open `C:\Users\Rushil\OneDrive\Documents\ChatGPT\Paytm` in Android Studio or VS Code. Open the whole Flutter project, not just its `android` folder.

```powershell
cd C:\Users\Rushil\OneDrive\Documents\ChatGPT\Paytm
flutter pub get
flutter doctor
```

## 2. Try the app without an API key

Transfer `build/app/outputs/flutter-apk/app-debug.apk` to your Android phone. Open it, allow installation from that file source if Android asks, and install FINPATH. The calculation, sample-document, draft-claim and local-assistant journeys work without a backend.

This prebuilt APK uses `http://127.0.0.1:8080` for the backend, suitable for a physical phone connected via the USB forwarding below. A standalone phone has no server at that address; the local demo still works.

## 3. Enable Gemini

Paste your key into `backend/.env`:

```dotenv
GEMINI_API_KEY=your_key_here
```

Keep the key in the backend only. Start it in a separate terminal and leave that terminal running:

```powershell
cd C:\Users\Rushil\OneDrive\Documents\ChatGPT\Paytm\backend
dart run bin/server.dart
```

## 4. Run on your physical phone via USB (recommended)

Enable Developer options on your phone (usually by tapping **Build number** seven times), then enable **USB debugging**. Connect the phone with a data-capable USB cable, unlock it and approve its debugging prompt.

In the project terminal:

```powershell
flutter devices
```

Copy the phone's device ID from that output, then run:

```powershell
.\scripts\run_android.ps1 -DeviceId "YOUR_DEVICE_ID"
```

The helper installs dependencies, forwards the phone's port 8080 to your computer and launches Flutter with the correct backend address. Leave USB connected while using Gemini. The computer needs internet.

If using the prebuilt APK instead, only the forwarding step is needed after installation:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" -s "YOUR_DEVICE_ID" reverse tcp:8080 tcp:8080
```

In FINPATH, open **Privacy & consent → Check connection**, then enable **External AI processing**. A connection check confirms backend configuration; sending a question confirms actual Gemini access and quota.

## 5. Or use an Android emulator

Create/start an emulator in Android Studio's Device Manager. Run `flutter devices` and copy its ID:

```powershell
.\scripts\run_android.ps1 -DeviceId "emulator-5554" -Emulator
```

Emulators use `http://10.0.2.2:8080` to reach the computer. This address differs from the USB phone setup.

## Quick demo checklist

1. **Overview:** enter “Buy a bike for 1.5 lakh”. AI consent off uses local matching; consent on uses Gemini with an explicit local fallback if unavailable.
2. **Plan & compare:** move the sliders and test an income drop. Check the EMI, interest, remaining cash and buffer.
3. **Documents:** try the sample payslip, review extracted values and confirm autofill.
4. **Your journey:** review the application, acknowledge the demo and create its saved snapshot.
5. **Insurance claims:** fill the sample details, tick ready documents, save/copy the draft and advance the demo tracker.
6. **Assistant:** ask about the EMI; try the scam and contract samples. For voice, enable voice consent and grant microphone permission.
7. **Privacy:** review the access log, revoke consent or export data. Restart the app to check local persistence.

## Common issues

- **No device:** try another cable/USB port, unlock the phone and accept USB debugging. `flutter doctor` identifies Android SDK issues.
- **Backend unavailable:** keep the backend terminal running, repeat `adb reverse` after reconnecting USB, and check the selected build's API address.
- **Gemini error:** check key, model access and quota; restart the backend after editing `.env`.
- **Microphone unavailable:** allow Android microphone permission and ensure a speech recognition service/language is installed. Typing remains available.
- **Install failed because of a different signature:** uninstall an older FINPATH build only if you no longer need its locally stored demo data, then install this build.
- **Disk space:** keep several GB free for Android build intermediates. Rebuild the APK with `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080`.

Loan approvals, claim decisions and financial providers are simulated. No actual submission or money transfer occurs.
