import CommandLineKit
import Foundation

var flags = Flags()

let filePath = flags.string("f", "filePathToNotarize", description: "zip or pkg to upload for notarization")
let primaryBundleId = flags.string("b", "primary-bundle-id", description: "The primary bundle id of the app being notarized")
let username = flags.string("u", "username", description: "username for the apple id being used to notarize")
let password = flags.string("p", "password", description: "password for the apple id being used to notarize")
let help = flags.option("h", "help", description: "provides this...")

func main() {
    validate()
    if  let filePath = filePath.value,
        let primaryBundleId = primaryBundleId.value,
        let username = username.value,
        let password = password.value
    {
        let notarize = Notarize(bundleID: primaryBundleId, username: username, password: password)
        notarize.uploadAndStaple(filePath: filePath)
    } else {
        print("validation failed, one of the parameters is empty")
    }
}

func validate() {
    if let failure = flags.parsingFailure() {
        print(failure)
        exit(1)
    }
    guard !help.wasSet else {
        print(flags.usageDescription())
        exit(0)
    }
    
    guard filePath.wasSet else {
        print("file path must be set")
        exit(1)
    }
    
    guard primaryBundleId.wasSet else {
        print("primary bundle it must be set")
        exit(1)
    }
    
    guard username.wasSet else {
        print("username must be set... for now")
        exit(1)
    }
    
    guard password.wasSet else {
        print("password must be set... for now")
        exit(1)
    }
}

print("🎬")
main()
print("🏁")
