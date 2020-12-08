//
//  DemoCasesViewController.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import UIKit

class DemoCasesViewController: UIViewController {
    
    enum Sections: String, CaseIterable {
        case viewModes = "MTKView Modes"
        case demos = "Demos"
    }
    
    enum ViewModes:String, CaseIterable {
        case delegate = "Delegate Mode"
        case loopDriven = "Loop Driven"
        case needsBased = "Needs Based Render"
    }
    
    enum DemoCases: String, CaseIterable {
        case triangle = "Triangle"
        case rectangle = "Rectangle"
        case texture = "Texture"
        case scribble = "Scribble"
    }

    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.bounds, style: .grouped)
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
        let section = Sections.allCases[indexPath.section]
        switch section {
        case .viewModes:
            let mode = ViewModes.allCases[indexPath.row]
            let modeTestVC = MTKViewModesViewController()
            modeTestVC.mode = mode
            navigationController?.pushViewController(modeTestVC, animated: true)
        case .demos:
            let demo = DemoCases.allCases[indexPath.row]
            switch demo {
            case .scribble:
                let caseVC = ScribbleDemoViewController()
                navigationController?.pushViewController(caseVC, animated: true)
            default:
                let caseVC = CaseDisplayViewController()
                caseVC.demoCase = demo
                navigationController?.pushViewController(caseVC, animated: true)
            }
        }
    }
}

extension DemoCasesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Sections.allCases[section]
        switch section {
        case .viewModes:
            return ViewModes.allCases.count
        case .demos:
            return DemoCases.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        let section = Sections.allCases[indexPath.section]
        switch section {
        case .viewModes:
            let mode = ViewModes.allCases[indexPath.row]
            cell.textLabel?.text = mode.rawValue
        case .demos:
            let demo = DemoCases.allCases[indexPath.row]
            cell.textLabel?.text = demo.rawValue
        }
        return cell
    }
}
