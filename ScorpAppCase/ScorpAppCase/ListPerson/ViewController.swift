//
//  ViewController.swift
//  ScorpAppCase
//
//  Created by Yavuz Selim Bitmez on 4.09.2021.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var refresherButton: UIButton!
    let label = UILabel()
    var nextPage:String? = nil
    var increasePage = 0
    var isLoading = true{
        didSet{
            self.indicator.startAnimating()
        }
    }

    var personList:[Person]?{
        didSet{
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Bundle.main.loadNibNamed("ViewController", owner: self, options: nil)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        indicator.startAnimating()
        getPersonList()
        refresherButton.layer.cornerRadius = 15
        //created with programmatic
        label.isHidden = false
        label.textAlignment = .center
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.tableView.centerYAnchor).isActive = true
        label.widthAnchor.constraint(equalToConstant: 300).isActive = true
        label.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let refreshControl = UIRefreshControl()
        let title = NSLocalizedString("Pull to refresh...", comment: "Pull to refresh")
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.addTarget(self, action: #selector(refreshOptions(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshOptions(sender: UIRefreshControl) {
        self.refreshAll()
        sender.endRefreshing()
    }
    func refreshAll(){
        personList?.removeAll()
        self.nextPage = nil
        self.increasePage = 0
        startLoadingAnimate()
        getPersonList()
    }
    func startLoadingAnimate(){
        self.indicator.startAnimating()
        self.indicator.isHidden = false
        self.tableView.isHidden = true
    }
    func stopLoadingAnimate(){
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
        self.tableView.isHidden = false
    }
    func getPersonList(){
        self.isLoading = true
        DataSource.fetch(next: self.nextPage) { response, error in
            if response?.people.count == 0 {
                self.refresherButton.isHidden = false
                self.tableView.isHidden = true
                self.label.text = "No one here :)"
            }else if (error == nil){
                if(self.increasePage > 0){
                    for person in response!.people{
                        if self.personList!.contains(where: {$0.id == person.id}) {
                           print("I founded same.")
                        } else {
                            self.personList?.append(person)
                        }
                    }
                    self.isLoading = false
                }else {
                    self.personList = response!.people
                    self.personList = self.removeDuplicateElements(persons: response!.people)
                    self.isLoading = false

                }
                self.stopLoadingAnimate()

            }else {
                self.refresherButton.isHidden = false
                self.tableView.isHidden = true
                self.label.text = error?.errorDescription
                self.label.textColor = .black
                print("***Error \(String(describing: error?.errorDescription))")

            }

        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = self.view.frame.size.height
        
        if(contentHeight != 0 && (yPosition+screenHeight) >= contentHeight && self.isLoading == false) {
            increasePage = increasePage + 1
            self.nextPage = String(increasePage)
            self.getPersonList()
            self.indicator.startAnimating()
            print("***scrollViewWillBeginDragging\(increasePage)")

        }
    }
    
    @IBAction func refresherButtonAction(_ sender: Any) {
        self.refreshAll()
        self.refresherButton.isHidden = true
        self.label.isHidden = true

    }
    
    func removeDuplicateElements(persons: [Person]) -> [Person] {
        var uniquePersons = [Person]()
        for person in persons {
            if !uniquePersons.contains(where: {$0.id == person.id }) {
                uniquePersons.append(person)
            }
        }
        return uniquePersons
    }
    


}
extension ViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return personList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell")!
        cell.selectionStyle = .none
        let fullName = personList?[indexPath.row].fullName
        let id = "(\(personList![indexPath.row].id))"
        cell.textLabel?.text = fullName! + id
        return cell
    }
    
    
}
