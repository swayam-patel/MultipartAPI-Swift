# MultipartAPI-Swift

A focused demo showing how to upload files — images, videos, audio — to a server using `multipart/form-data` in Swift, with nothing but `URLSession`. No Alamofire, no third-party libraries.

If you've handled JSON APIs before but hit a wall when you needed to upload a file, this is the missing piece.

---

## What's Covered

| Topic | Detail |
|-------|--------|
| HTTP method | `POST` via `URLSession.uploadTask` |
| Content type | `multipart/form-data` with a UUID boundary |
| Payload | Image (`UIImage` → `pngData()`) |
| Response | JSON parsed with `JSONSerialization` |
| Dependencies | None — standard library only |

---

## How Multipart Works

Regular JSON APIs send a flat dictionary. Multipart is different — it wraps each piece of data (fields, files) in its own **part**, separated by a unique **boundary** string. The server reads the boundary to know where one part ends and the next begins.

A raw multipart body looks like this:

```
--<boundary>\r\n
Content-Disposition: form-data; name="file"; filename="swift_upload.png"\r\n
Content-Type: image/png\r\n
\r\n
<raw PNG bytes here>
\r\n--<boundary>--\r\n
```

The `\r\n` line endings and the `--` prefix/suffix on the boundary are **required** — the server will reject the request if they're off.

---

## The Implementation

```swift
func multipartAPICallwithJSONSerialization(apiName: String) {
    guard let url = URL(string: apiName) else {
        print("Invalid URL"); return
    }

    // Step 1 — Generate a unique boundary string
    // UUID is perfect here: unique per request, no risk of collision with file data
    let boundary = UUID().uuidString

    // Step 2 — Build the request
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"

    // Step 3 — Set the Content-Type header, including the boundary
    // The server uses this to know where each part starts and ends
    urlRequest.setValue(
        "multipart/form-data; boundary=\(boundary)",
        forHTTPHeaderField: "Content-Type"
    )

    // Step 4 — Build the body manually by appending raw Data
    var body = Data()

    let parameterName = "file"          // the field name your server expects
    let fileName      = "swift_upload.png"
    let image         = UIImage(named: "test")!

    // Opening boundary
    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)

    // Part headers — tells the server this part is a file upload
    body.append("Content-Disposition: form-data; name=\"\(parameterName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)

    // The actual file bytes
    body.append(image.pngData()!)

    // Closing boundary — the trailing -- signals end of all parts
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    // Step 5 — Use uploadTask (not dataTask) to send the body
    let task = URLSession.shared.uploadTask(
        with: urlRequest,
        from: body
    ) { responseData, response, error in
        guard error == nil, let responseData = responseData else {
            print(error?.localizedDescription ?? "Unknown error")
            return
        }

        // Step 6 — Parse the JSON response
        if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
            print(json)
        }
    }

    task.resume()
}
```

---

## Using It In Your Own Project

### Uploading a UIImage

```swift
// Swap in your own endpoint and field name
let endpoint = "https://api.yourapp.com/v1/avatar"
let image     = UIImage(named: "profile")!
let boundary  = UUID().uuidString

var request = URLRequest(url: URL(string: endpoint)!)
request.httpMethod = "POST"
request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
request.addValue("Bearer \(yourAuthToken)", forHTTPHeaderField: "Authorization")

var body = Data()
body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.png\"\r\n".data(using: .utf8)!)
body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
body.append(image.pngData()!)
body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

URLSession.shared.uploadTask(with: request, from: body) { data, _, error in
    guard let data = data else { return }
    print(try? JSONSerialization.jsonObject(with: data))
}.resume()
```

### Sending a File + Text Fields Together

You can include regular text fields in the same request by adding extra parts before the file:

```swift
// Add a text field (e.g. a username alongside the image)
body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"username\"\r\n\r\n".data(using: .utf8)!)
body.append("swayam".data(using: .utf8)!)

// Then add the file part as normal
body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.png\"\r\n".data(using: .utf8)!)
body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
body.append(image.pngData()!)

body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
```

### Uploading a Video or Audio File

The only things that change are the `Content-Type` and how you get the file bytes:

```swift
// Video
body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
body.append(try! Data(contentsOf: videoFileURL))

// Audio
body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
body.append(try! Data(contentsOf: audioFileURL))
```

---

## `uploadTask` vs `dataTask`

Both work for POST requests, but they serve different purposes:

| | `dataTask` | `uploadTask` |
|---|---|---|
| Body via | `request.httpBody` | Separate `Data` argument |
| Best for | JSON payloads, small bodies | File uploads, large data |
| Background uploads | ❌ | ✅ (with background session) |

For file uploads, always prefer `uploadTask` — it's designed for it and supports background sessions when you need them.

---

## Common Mistakes

**Missing `\r\n` line endings** — HTTP multipart is strict about this. Using `\n` alone will cause the server to reject the body silently.

**Wrong boundary in the header** — The boundary in `Content-Type` must exactly match the one used in the body. Since we generate it once with `UUID().uuidString` and reuse it, this is handled automatically.

**Forgetting `task.resume()`** — URLSession tasks start suspended. Without `.resume()`, nothing is sent.

**Force-unwrapping image data** — `image.pngData()` can return `nil` for non-PNG compatible images. In production, guard against this.

---

## Requirements

| | |
|---|---|
| Language | Swift 5+ |
| Platform | iOS 13+ |
| Dependencies | None |
| Tools | Xcode 13+ |

---

## Getting Started

```bash
git clone https://github.com/swayam-patel/MultipartAPI-Swift.git
```

Open `MultipartAPIIntegration.xcodeproj` in Xcode. The project includes a `test` image asset used by the demo — hit **Run** and watch the console for the server's response.

To test with your own image, replace `UIImage(named: "test")` with any `UIImage` instance.

---

## Related

- [RestAPI-Swift](https://github.com/swayam-patel/RestAPI-Swift) — GET and POST with JSON payloads, same URLSession-only approach
- [swift-snippets](https://github.com/swayam-patel/swift-snippets) — drop-in Swift utilities including async networking helpers
