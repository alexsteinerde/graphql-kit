import XCTest

import vapor_graphitiTests

var tests = [XCTestCaseEntry]()
tests += GraphQLKitTests.allTests()
XCTMain(tests)
