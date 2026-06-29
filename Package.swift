// swift-tools-version:5.3
import PackageDescription

// BEGIN KMMBRIDGE VARIABLES BLOCK (do not edit)
let remoteKotlinUrl = "https://github.com/steadysense/nfctlog-mobile-release/releases/download/0.5.0-dev.26062901/nfctlog-kmmbridge-0.5.0-dev.26062901.zip"
let remoteKotlinChecksum = "a73174e8ac62364bb7e63ea5813cb9b44039a7bb9c821bd28e782427fe15cf82"
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
