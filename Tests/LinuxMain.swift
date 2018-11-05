import XCTest

import macOSNotaryTests

var tests = [XCTestCaseEntry]()
tests += macOSNotaryTests.allTests()
XCTMain(tests)