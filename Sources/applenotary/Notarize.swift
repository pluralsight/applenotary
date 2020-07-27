//
//  Notarize.swift
//  applenotary
//
//  Created by Adam Findley on 7/26/19.
//

import Foundation

class Notarize {
    let bundleID: String
    let username: String
    let password: String

    required init(bundleID: String, username: String, password: String) {
        self.bundleID = bundleID
        self.username = username
        self.password = password
    }

    func uploadAndStaple(filePaths: [String]) {

        var uploadPaths = filePaths
        let stapleFilePaths = filePaths
        var uploadUUIDs: [String] = []

        // Uploads
        for (index, uploadPath) in uploadPaths.enumerated()  {
            let ext = NSURL(fileURLWithPath: uploadPath).pathExtension
            if ext == "app" {
                uploadPaths[index] = zip(filePath: uploadPath)
            }

            let notarizeUploadResponse = upload(filePath: uploadPaths[index])

            if let uuid = notarizeUploadResponse.notarizationUpload?.RequestUUID {
                print("start observing status of \(uuid)")
                uploadUUIDs.append(uuid)
            } else {
                print("show errors")
                notarizeUploadResponse.productErrors?.forEach { error in
                    print(error)
                }
                exit(1)
            }
        }

        waitForProcessing(uploadUUIDs: uploadUUIDs, username: username, password: password)

        for stapleFilePath in stapleFilePaths {
            staple(filePath: stapleFilePath)
        }
    }

    private func upload(filePath: String) -> NotarizeUploadResponse {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "xcrun", "altool",
            "-t", "osx",
            "-f", filePath,
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

    private func zip(filePath: String) -> String {
        print("zipping")

        guard let filename = NSURL(fileURLWithPath: filePath).lastPathComponent else {
            print("unable to zip")
            exit(1)
        }

        let zipURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)
            .appendingPathExtension("zip")
        print(zipURL)

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "ditto", "-c", "-k", "--keepParent",
            filePath, zipURL.path
        ]

        let outpipe = Pipe()
        task.standardOutput = outpipe

        task.launch()

        task.waitUntilExit()

        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()


        if task.terminationStatus == 0 {
            print("zip success!")
        } else {
            if let string = String(data: outdata, encoding: .utf8) {
                print("zip failed: \(string)")
                exit(1)
            } else {
                print("unable to read out put of staple")
                exit(1)
            }
        }

        return zipURL.path
    }

    private func waitForProcessing(uploadUUIDs: [String], username: String, password: String) {

        sleep(10)

        var finished = uploadUUIDs.count
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "xcrun", "altool",
            "-u", username,
            "-p", password,
            "--notarization-history", "0",
            "--output-format", "xml"
        ]

        let outpipe = Pipe()
        task.standardOutput = outpipe

        task.launch()

        task.waitUntilExit()

        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let note = NotarizeUploadResponse.create(from: outdata)

        if let infos =  note.notarizationHistory?.items {
            for info in infos {
                if let uuid = info.requestUUID, uploadUUIDs.contains(uuid) {
                    switch info.status {
                    case .inProgress:
                        print("notarization in progress for \(uuid), continuing to wait")
                    case .success:
                        print("approved! \(uuid)")
                        finished -= 1
                    case .invalid:
                        if let url = info.logFileUrl {
                            print("the app failed notarization see link for details: \(url)")

                        } else {
                            print("the app failed notarization: \(note)")
                        }
                        exit(1)
                    }
                }
            }
        }
        if finished > 0 {
            waitForProcessing(uploadUUIDs: uploadUUIDs, username: username, password: password)
        } else {
            print("all items notarized!")
        }
    }

    private func staple(filePath: String) {
        print("stapling \(filePath)")
        sleep(5) //give apple a few to be read to staple
        //xcrun stapler staple Pluralsight\ -\ Beta.app

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "xcrun", "stapler",
            "staple", filePath
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
            print("unable to read output of staple")
            exit(1)
        }
    }

}
