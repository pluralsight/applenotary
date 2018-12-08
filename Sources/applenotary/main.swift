import CommandLineKit
import Foundation

var flags = Flags()

let stapleFilePath = flags.string("s", "filePathToStaple", description: "the executable that needs to the notarization stapled to")
let filePath = flags.string("f", "filePathToNotarize", description: "zip or pkg to upload for notarization")
let primaryBundleId = flags.string("b", "primary-bundle-id", description: "The primary bundle id of the app being notarized")
let username = flags.string("u", "username", description: "username for the apple id being used to notarize")
let password = flags.string("p", "password", description: "password for the apple id being used to notarize")
let help = flags.option("h", "help", description: "provides this...")

func main() {
    validate()
    
    let notarizeUploadResponse = upload(file: filePath.value!, bundleId: primaryBundleId.value!, username: username.value!, password: password.value!)
    
    if let uuid = notarizeUploadResponse.notarizationUpload?.RequestUUID {
        print("start observing status")
        
        waitForProcessing(with: uuid, username: username.value!, password: password.value!)
    } else {
        print("show errors")
        notarizeUploadResponse.productErrors?.forEach { error in
            print(error)
        }
        exit(1)
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
    
    guard stapleFilePath.wasSet else {
        print("stapleFilePath must be set")
        exit(1)
    }
}

func upload(file: String, bundleId: String, username: String, password: String) -> NotarizeUploadResponse {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = [
        "xcrun", "altool",
        "-t", "osx",
        "-f", file,
        "--primary-bundle-id", bundleId,
        "-u", username,
        "-p", password,
        "--notarize-app",
        "--output-format", "xml"
    ]
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    print("upload")
    task.launch()
    
    task.waitUntilExit()
    print("done uploading, processing result")
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    
    let note = NotarizeUploadResponse.create(from: outdata)
    print("done processing result")
    return note
}

func staple(file: String) {
    print("stapling")
    sleep(5) //give apple a few to be read to staple
    //xcrun stapler staple Pluralsight\ -\ Beta.app
    
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = [
        "xcrun", "stapler",
        "staple", file
    ]
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    
    task.launch()
    
    task.waitUntilExit()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    
    if let string = String(data: outdata, encoding: .utf8) {
        if string.contains("The staple and validate action worked!") {
            print("staple success!")
        } else {
            print("staple failed: \(string)")
            exit(1)
        }
    } else {
        print("unable to read out put of staple")
        exit(1)
    }
}

func waitForProcessing(with uuid: String, username: String, password: String) {
    sleep(10)
    
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = [
        "xcrun", "altool",
        "-u", username,
        "-p", password,
        "--notarization-info", uuid,
        "--output-format", "xml"
    ]
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    
    task.launch()
    
    task.waitUntilExit()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    
    let note = NotarizeUploadResponse.create(from: outdata)
    
    if let status = note.notarizationInfo?.status {
        switch status {
        case .inProgress:
            print("notarization in progress, continuing to wait")
            waitForProcessing(with: uuid, username: username, password: password)
        case .success:
            print("approved!")
            staple(file: stapleFilePath.value!)
        case .invalid:
            if let url = note.notarizationInfo?.logFileUrl {
                print("the app failed notarization see link for details: \(url)")
                
            } else {
                print("the app failed notarization: \(note)")
            }
            exit(1)
        }
    } else {
        if let errors = note.productErrors, errors.contains(where: { $0.code == 1519 }) {
            print("UUID not found trying again in a few")
            sleep(10)
            waitForProcessing(with: uuid, username: username, password: password)
        } else {
            if note.productErrors?.isEmpty ?? false {
                let outputString = String(data: outdata, encoding: .utf8)
                print("an unkown error occurred, showing raw output: \(String(describing: outputString))")
            } else {
                print("an error occured: \(String(describing: note.productErrors))")
            }
        }
        
        //do we have error, is key not found? try again in a second?
        print("unable to get status")
        exit(1)
    }
    
}

print("🎬")
main()
print("🏁")



