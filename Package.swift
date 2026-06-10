// swift-tools-version:5.3
import PackageDescription

// BEGIN KMMBRIDGE VARIABLES BLOCK (do not edit)
let remoteKotlinUrl = "https://github.com/steadysense/nfctlog-mobile-release/releases/download/0.4.3/nfctlog-kmmbridge-0.4.3.zip"
let remoteKotlinChecksum = "863bbf73d81bfc910b64cd74d2c6a47a43b9ce89f8111e3659632af990ed504b"
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
