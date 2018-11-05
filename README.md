# applenotary

This tool is designed to synchronously notarize your macOS app with Apple. This is very barebones right now, pull requests appreciated.

I'm not providing a binary for now, you will need to clone the project and compile it yourself.

Example:

`./applenotary -f myApp.dmg -b com.my.app -u my@apple.id -p mypassword -s myApp.dmg`

```
-f file to upload to Apple for notarization
-b the main bundle identifier of the app
-u username
-p password. You can pass your password or pass @env:mypass or @keychain:mystoredpassword (see xcrun altool --help for more info)
```

This app requires Xcode 10 or the commandline tool equivalence. I have not tested this with commandline tools. It also required an active internet connection to upload and retrieve data from Apple.

This app does not store any data except in memory during the lifetime of the app execution.
