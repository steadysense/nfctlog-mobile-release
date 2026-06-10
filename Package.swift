// swift-tools-version:5.3
import PackageDescription

// BEGIN KMMBRIDGE VARIABLES BLOCK (do not edit)
let remoteKotlinUrl = "https://github.com/steadysense/nfctlog-mobile-release/releases/download/0.4.1/nfctlog-kmmbridge-0.4.1.zip"
let remoteKotlinChecksum = "efc99635af542d31fb60c5c2ba145c0cea2db5a3ba1568ec7c5a22f05e5f4647"
let packageName = "nfctlog"
// END KMMBRIDGE BLOCK

let package = Package(
    name: packageName,
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: packageName,
            targets: [packageName]
        ),
    ],
    targets: [
        .binaryTarget(
            name: packageName,
            url: remoteKotlinUrl,
            checksum: remoteKotlinChecksum
        )
        ,
    ]
)
