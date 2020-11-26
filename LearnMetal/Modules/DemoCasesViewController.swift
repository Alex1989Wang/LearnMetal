//
//  DemoCasesViewController.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import UIKit

class DemoCasesViewController: UIViewController {
    
    enum DemoCases: String, CaseIterable {
        case triangle = "Triangle"
        case rectangle = "Rectangle"
    }

    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        let constraints = [view.topAnchor.constraint(equalTo: tableView.topAnchor),
                           view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
                           view.rightAnchor.constraint(equalTo: tableView.rightAnchor),
                           view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)]
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(constraints)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

extension DemoCasesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let demo = DemoCases.allCases[indexPath.row]
        let caseVC = CaseDisplayViewController()
        caseVC.demoCase = demo
        navigationController?.pushViewController(caseVC, animated: true)
    }
}

extension DemoCasesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DemoCases.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        let demo = DemoCases.allCases[indexPath.row]
        cell.textLabel?.text = demo.rawValue
        return cell
    }
}
