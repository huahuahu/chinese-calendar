import Foundation
import Synchronization

/// 完全拦截测试请求；第一块响应发送后等待测试放行，不访问任何下载源。
final class SeedDownloadURLProtocol: URLProtocol, @unchecked Sendable {
    /// URLProtocol 的框架状态由 Foundation 管理；本类型所有可变状态均受 Mutex 保护。
    private struct LoadingState {
        var task: Task<Void, Never>?
        var stopped = false
    }

    struct Observations {
        var started = false
        var rangeHeader: String?
        var finished = false
    }

    final class Response: Sendable {
        let statusCode: Int
        let body: Data
        let includesContentLength: Bool
        let firstChunkSize: Int
        let contentRange: String?
        let failureAfterFirstChunk: URLError?
        let observations = Mutex(Observations())
        let remainder = AsyncStream<Void>.makeStream()

        init(
            statusCode: Int, body: Data, includesContentLength: Bool, firstChunkSize: Int,
            contentRange: String? = nil, failureAfterFirstChunk: URLError? = nil
        ) {
            self.statusCode = statusCode
            self.body = body
            self.includesContentLength = includesContentLength
            self.firstChunkSize = firstChunkSize
            self.contentRange = contentRange
            self.failureAfterFirstChunk = failureAfterFirstChunk
        }
    }

    struct RouteState {
        var responses: [Response]
        var requests: [URLRequest] = []
    }

    /// 同一 URL 按顺序返回响应，并记录包括额外重试在内的每个请求。
    final class Route: Sendable {
        let state: Mutex<RouteState>

        init(responses: [Response]) {
            state = Mutex(RouteState(responses: responses))
        }

        func nextResponse(for request: URLRequest) -> Response? {
            state.withLock { state in
                state.requests.append(request)
                return state.responses.isEmpty ? nil : state.responses.removeFirst()
            }
        }
    }

    static let routes = Mutex<[URL: Route]>([:])
    private let loading = Mutex(LoadingState())

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let route = Self.routes.withLock({ $0[url] }),
              let response = route.nextResponse(for: request)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        response.observations.withLock {
            $0.started = true
            $0.rangeHeader = request.value(forHTTPHeaderField: "Range")
        }
        let task = Task {
            var headers = response.includesContentLength ? ["Content-Length": "\(response.body.count)"] : [:]
            headers["Content-Range"] = response.contentRange
            guard let httpResponse = HTTPURLResponse(
                url: url, statusCode: response.statusCode, httpVersion: "HTTP/1.1", headerFields: headers
            ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(response.body.prefix(response.firstChunkSize)))
            for await _ in response.remainder.stream {
                break
            }
            guard !Task.isCancelled else { return }
            if let error = response.failureAfterFirstChunk {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            client?.urlProtocol(self, didLoad: Data(response.body.dropFirst(response.firstChunkSize)))
            response.observations.withLock { $0.finished = true }
            client?.urlProtocolDidFinishLoading(self)
        }
        loading.withLock { state in
            if state.stopped {
                task.cancel()
            } else {
                state.task = task
            }
        }
    }

    override func stopLoading() {
        let task = loading.withLock { state in
            state.stopped = true
            return state.task
        }
        task?.cancel()
    }
}
