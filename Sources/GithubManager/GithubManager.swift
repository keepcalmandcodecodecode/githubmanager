import Foundation

public class GithubManager {

    var task: URLSessionDataTask?

    public init() { }

    public func searchRepositories(with query: String, completion: @escaping ([Repository]) -> ()) {
        let defaultSession = URLSession(configuration: .default)
        let url = GithubEndpoint.search(query).buildUrl()
        var repositories = [Repository]()
        task = defaultSession.dataTask(with: url) { [unowned self] (data, _, _) in
            defer {
                self.task = nil
                DispatchQueue.main.async {
                    completion(repositories)
                }
            }

            guard let data = data else { return }

            let response: [String: Any]
            do {
                response = try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
            } catch {
                return
            }

            guard let items = response["items"] as? [[String: Any]] else { return }

            repositories = items.compactMap { self.parse(dictionary: $0) }
        }
        task?.resume()
    }

    private func parse(dictionary: [String: Any]) -> Repository? {
        guard let name = dictionary["name"] as? String else {
            return nil
        }

        return Repository(name: name)
    }

}

enum GithubEndpoint {
    static let baseUrl = "https://api.github.com"

    case search(_ q: String)


    var path: String {
        switch self {
        case .search(_):
            return "/search/repositories"
        }
    }

    var parameters: String? {
        switch self {
        case .search(let query):
            return "?q=\(query)"
        }
    }

    func buildUrl() -> URL {
        var absolutePath = "\(GithubEndpoint.baseUrl)\(path)"
        if let parameters = parameters {
            absolutePath += parameters
        }
        return URL(string: absolutePath)!
    }
}
