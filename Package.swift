// swift-tools-version:5.3
import PackageDescription

// BEGIN KMMBRIDGE VARIABLES BLOCK (do not edit)
let remoteKotlinUrl = "https://github.com/steadysense/nfctlog-mobile-release/releases/download/0.5.1/nfctlog-kmmbridge-0.5.1.zip"
let remoteKotlinChecksum = "fc74189b5bbc89fa736ed29086a410be12cdda1992ca57976c2d3f7fbeb69508"
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
