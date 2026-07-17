// swift-tools-version:5.3
import PackageDescription

// BEGIN KMMBRIDGE VARIABLES BLOCK (do not edit)
let remoteKotlinUrl = "https://github.com/steadysense/nfctlog-mobile-release/releases/download/0.4.4/nfctlog-kmmbridge-0.4.4.zip"
let remoteKotlinChecksum = "c9d9f1e1eec830e39e015e68b17d134309e3ec812f678ce60b450bbe7729860b"
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
