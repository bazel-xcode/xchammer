import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(XCodeBuildLog.allTests),
            testCase(RecordTests.allTests),
        ]
    }
#endif
