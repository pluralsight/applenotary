//
//  Notarize.swift
//  applenotary
//
//  Created by Adam Findley on 7/26/19.
//

import Foundation

class Notarize {
    let file: String
    let stapleFile: String
    let bundleID: String
    let username: String
    let password: String

    required init(file: String, stapleFile: String, bundleID: String, username: String, password: String) {
        self.file = file
        self.stapleFile = stapleFile
        self.bundleID = bundleID
        self.username = username
        self.password = password
    }

    func uploadAndStaple() {
        let notarizeUploadResponse = upload()

        if let uuid = notarizeUploadResponse.notarizationUpload?.RequestUUID {
            print("start observing status")

            waitForProcessing(with: uuid, username: username, password: password)
        } else {
            print("show errors")
            notarizeUploadResponse.productErrors?.forEach { error in
                print(error)
            }
            exit(1)

        }
    }

    func upload() -> NotarizeUploadResponse {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "xcrun", "altool",
            "-t", "osx",
            "-f", file,
            "--primary-bundle-id", bundleID,
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
                staple(file: stapleFile)
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
}
