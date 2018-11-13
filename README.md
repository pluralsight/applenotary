# applenotary

This tool is designed to synchronously notarize your macOS app with Apple and then staple the provided file. This is very barebones right now, pull requests appreciated.

I'm not providing a binary for now, you will need to clone the project and compile it yourself. You can compile it using `swift build` or `swift build -c release` in the cloned directory. There are other build configurations that may be appropriate for you.

Here is a usage example of the tool after having built it:

`./applenotary -f myApp.dmg -b com.my.app -u my@apple.id -p mypassword -s myApp.dmg`

```
-f file to upload to Apple for notarization
-b the main bundle identifier of the app
-u username
-p password. You can pass your password or pass @env:mypass or @keychain:mystoredpassword (see xcrun altool --help for more info)
-s the file to staple, this may be the same file you send to Apple for notarization, but in the case of it being a .app file you have to zip it first, thus the need for -s and -f
```

This app requires Xcode 10 or the commandline tool equivalence. I have not tested this with commandline tools. It also requires an active internet connection to upload and retrieve data from Apple.

This app does not store any data except in memory during the lifetime of the app execution.
