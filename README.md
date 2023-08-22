# TorrentModel

TorrentModel is a Swift library that parses torrent files and extracts information from them.

## Installation

Use swift package manager to install TorrentModel.

```swift
.package(url: "https://github.com/nothingsh/TorrentModel", .upToNextMajor(from: "1.0.4")),
```

## Usage

Parse torrent file

```swift
import TorrentModel

let torrentModel = TorrentModel.decode(data: torrentFileData)
```

Encode & Decode BEncode
```swift
let bencode = BDecoder().decode(data: bencodeData)
let data = BEncoder().encode(bencode: bencode)
```

Bencode is a enum
```swift
enum Bencode {
    case int(Int)
    case string(Data)
    case list([Bencode])
    case dict([String : Bencode])
}
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
