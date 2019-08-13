@testable import XCConfigDumperCore
import XCTest

let sample = """
/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -x objective-c -target arm64-apple-ios13.0 -fmessage-length=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit=0 -std=gnu11 -fobjc-arc -fobjc-weak -fmodules -gmodules -fmodules-prune-interval=86400 -fmodules-prune-after=345600 -fbuild-session-file=/var/folders/m2/nmvs88ws0593v17kn4b_qxch0000gn/C/org.llvm.clang/ModuleCache.noindex/Session.modulevalidation -fmodules-validate-once-per-build-session -Wnon-modular-include-in-framework-module -Werror=non-modular-include-in-framework-module -Wno-trigraphs -fpascal-strings -O0 -fno-common -Wno-missing-field-initializers -Wno-missing-prototypes -Werror=return-type -Wdocumentation -Wunreachable-code -Wno-implicit-atomic-properties -Werror=deprecated-objc-isa-usage -Wno-objc-interface-ivars -Werror=objc-root-class -Wno-arc-repeated-use-of-weak -Wimplicit-retain-self -Wduplicate-method-match -Wno-missing-braces -Wparentheses -Wswitch -Wunused-function -Wno-unused-label -Wno-unused-parameter -Wunused-variable -Wunused-value -Wempty-body -Wuninitialized -Wconditional-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wconstant-conversion -Wint-conversion -Wbool-conversion -Wenum-conversion -Wno-float-conversion -Wnon-literal-null-conversion -Wobjc-literal-conversion -Wshorten-64-to-32 -Wpointer-sign -Wno-newline-eof -Wno-selector -Wno-strict-selector-match -Wundeclared-selector -Wdeprecated-implementations -DDEBUG=1 -DOBJC_OLD_DISPATCH_PROTOTYPES=0 -isysroot /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.0.sdk -fstrict-aliasing -Wprotocol -Wdeprecated-declarations -g -Wno-sign-conversion -Winfinite-recursion -Wcomma -Wblock-capture-autoreleasing -Wstrict-prototypes -Wno-semicolon-before-method-body -Wunguarded-availability -fembed-bitcode-marker -iquote /Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Test-generated-files.hmap -I/Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Test-own-target-headers.hmap -I/Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Test-all-target-headers.hmap -iquote /Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Test-project-headers.hmap -I/Users/vsolomenchuk/Downloads/Test/build/Debug-iphoneos/include -I/Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/DerivedSources-normal/arm64 -I/Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/DerivedSources/arm64 -I/Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/DerivedSources -F/Users/vsolomenchuk/Downloads/Test/build/Debug-iphoneos -MMD -MT dependencies -MF /Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Objects-normal/arm64/ViewController.d --serialize-diagnostics /Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Objects-normal/arm64/ViewController.dia -c /Users/vsolomenchuk/Downloads/Test/Test/ViewController.m -o /Users/vsolomenchuk/Downloads/Test/build/Test.build/Debug-iphoneos/Test.build/Objects-normal/arm64/ViewController.o
"""
final class XcodeBuildLogTests: XCTestCase {
    func testCompiler() {
        let parser = XcodeBuildLog(log: sample)
        XCTAssert(parser.records.first?.isCompiler ?? false)
    }

    func testObjcCompiler() {
        let parser = XcodeBuildLog(log: sample)
        XCTAssert(parser.records.first?.isObjcCompiler ?? false)
    }

    func testW() {
        let parser = XcodeBuildLog(log: "fake -Wa -Wb -Dx -Tr")
        let result = parser.records.first?.fields.filter {
            if case Field.w = $0 {
                return true
            } else {
                return false
            }
        } ?? []

        XCTAssertEqual(result, [Field.w("-Wa"), Field.w("-Wb")])
    }

    static var allTests = [
        ("testCompiler", testCompiler),
        ("testObjcCompiler", testObjcCompiler),
    ]
}
