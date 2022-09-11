import UIKit

class ViewController: UIViewController {
    var model: TestModel? {
        didSet {
            analyseInput()
        }
    }

    var answers: [String] = []
    var dsu: UnionFindQuickFind<String>?

    override func viewDidLoad() {
        super.viewDidLoad()

        getModel()
    }

    // parse model from json
    private func getModel() {
        if let url = Bundle.main.url(forResource: "test.in", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(TestModel.self, from: data)
                model = jsonData
            } catch {
                print("error:\(error)")
            }
        }
    }

    private func analyseInput() {
        guard let model = model else {
            return
        }

        for testCase in model.testCases {
            dsu = UnionFindQuickFind<String>()

            // convert dictionary to dsu
            for value in testCase.dictionary {
                guard
                    let firstValue = value.first?.lowercased(),
                    let secondValue = value.last?.lowercased()
                else { return }

                let firstIndex = dsu?.setOf(firstValue)
                let secondIndex = dsu?.setOf(secondValue)

                // check cases
                if firstIndex == nil && secondIndex == nil {
                    dsu?.addSetWith(firstValue)
                    dsu?.addSetWith(secondValue)
                    dsu?.unionSetsContaining(firstValue, and: secondValue)
                } else if firstIndex == nil {
                    dsu?.addSetWith(firstValue)
                    dsu?.unionSetsContaining(secondValue, and: firstValue)
                } else if secondIndex == nil {
                    dsu?.addSetWith(secondValue)
                    dsu?.unionSetsContaining(firstValue, and: secondValue)
                } else {
                    dsu?.unionSetsContaining(firstValue, and: secondValue)
                }
            }

            testCase.queries.forEach {
                answers.append(analyseQuery($0))
            }
        }

        answers.forEach {
            print($0)
        }
    }

    private func analyseQuery(_ query: [String]) -> String {
        guard
            let firstValue = query.first?.lowercased(),
            let secondValue = query.last?.lowercased()
        else { return "no words" }

        // check cases
        if firstValue != secondValue {
            let firstIndex = dsu?.setOf(firstValue)
            let secondIndex = dsu?.setOf(secondValue)

            if firstIndex == nil || secondIndex == nil {
                return "different"
            } else {
                if firstIndex == secondIndex {
                    return "synonyms"
                } else {
                    return "different"
                }
            }
        } else {
            return "synonyms"
        }
    }
}

// MARK: - DSU class
public struct UnionFindQuickFind<T: Hashable> {
    private var index = [T: Int]()
    private var parent = [Int]()
    private var size = [Int]()


    public mutating func addSetWith(_ element: T) {
        index[element] = parent.count
        parent.append(parent.count)
        size.append(1)
    }

    private mutating func setByIndex(_ index: Int) -> Int {
        return parent[index]
    }

    public mutating func setOf(_ element: T) -> Int? {
        if let indexOfElement = index[element] {
            return setByIndex(indexOfElement)
        } else {
            return nil
        }
    }

    public mutating func unionSetsContaining(_ firstElement: T, and secondElement: T) {
        if let firstSet = setOf(firstElement), let secondSet = setOf(secondElement) {
            if firstSet != secondSet {
                for index in 0..<parent.count {
                    if parent[index] == firstSet {
                        parent[index] = secondSet
                    }
                }

                size[secondSet] += size[firstSet]
            }
        }
    }

    public mutating func inSameSet(_ firstElement: T, and secondElement: T) -> Bool {
        if let firstSet = setOf(firstElement), let secondSet = setOf(secondElement) {
            return firstSet == secondSet
        } else {
            return false
        }
    }
}

// MARK: - JSON models
struct TestModel: Decodable {
    var t: Int
    var testCases: [TestCaseModel]

    enum CodingKeys: String, CodingKey {
        case t = "T"
        case testCases
    }
}

struct TestCaseModel: Decodable {
    var n: Int
    var q: Int
    var dictionary: [[String]]
    var queries: [[String]]

    enum CodingKeys: String, CodingKey {
        case n = "N"
        case q = "Q"
        case dictionary
        case queries
    }
}
