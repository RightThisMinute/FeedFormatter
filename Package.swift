import PackageDescription

let package = Package(
    name: "FeedFormatter",
    dependencies: [
      .Package(url: "https://github.com/Zewo/Axis.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/IBM-Swift/BlueSignals.git",
               majorVersion: 0, minor: 9),
      .Package(url: "https://github.com/RightThisMinute/CommandLine.git",
               majorVersion: 3, minor: 0),
      .Package(url: "https://github.com/Zewo/File.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Zewo/HTTP.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Zewo/HTTPServer.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Zewo/Mapper.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Zewo/POSIX.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Zewo/Venice.git",
               majorVersion: 0, minor: 14),
      .Package(url: "https://github.com/Danappelxx/MuttonChop.git",
               majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/behrang/YamlSwift.git",
               majorVersion: 3, minor: 1),
      .Package(url: "https://github.com/RightThisMinute/YAMLMapper.git",
               majorVersion: 0, minor: 1),
    ]
)
