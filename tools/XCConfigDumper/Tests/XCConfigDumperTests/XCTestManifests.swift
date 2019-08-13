import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(XcodeBuildLog.allTests),
            testCase(RecordTests.allTests),
        ]
    }
#endif
