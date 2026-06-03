# If emulator is not running:

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
emulator -avd Medium_Phone_API_35 -gpu host &

# Wait for boot, then install:

adb wait-for-device
adb install -r /path/to/your-app.apk

---

funza.apk is installed on the emulator (emulator-5554).

adb install -r ~/Downloads/ifunza.apk
→ Success
Open it on the emulator: open the app drawer and tap Ifunza (or whatever name the app shows).

To reinstall after an update:

adb install -r ~/Downloads/ifunza.apk
To launch from the terminal:

adb shell monkey -p $(adb shell pm list packages | grep -i ifunza | cut -d: -f2) -c android.intent.category.LAUNCHER 1
Or find the package name first:

adb shell pm list packages | grep -i ifunza
