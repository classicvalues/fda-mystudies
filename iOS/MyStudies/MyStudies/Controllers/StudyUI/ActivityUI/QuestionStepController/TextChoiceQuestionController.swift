// License Agreement for FDA MyStudies
// Copyright © 2017-2019 Harvard Pilgrim Health Care Institute (HPHCI) and its Contributors.
// Copyright 2020 Google LLC
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the &quot;Software&quot;), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
// Funding Source: Food and Drug Administration (“Funding Agency”) effective 18 September 2014 as
// Contract no. HHSF22320140030I/HHSF22301006T (the “Prime Contract”).
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
// OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import ResearchKit
import UIKit
import FirebaseAnalytics

/// A value type whose instances will have Other Choice configuration in TextChoiceQuestionStep .
struct OtherChoice {

  /// A Boolean value indicating other choice availablity.
  let isShowOtherCell: Bool

  /// A Boolean value indicating other choice TextField availablity.
  let isShowOtherField: Bool

  /// Text Choice title.
  let otherTitle: String

  /// Text Choice field placeholder.
  let placeholder: String

  /// A Boolean value indicating choice selection is mandatory.
  let isMandatory: Bool

  /// Details text of the choice.
  let detailText: String

  lazy var otherChoiceText = ""
  let isExclusive: Bool
  let value: String

  init(
    isShowOtherCell: Bool = false,
    isShowOtherField: Bool = true,
    otherTitle: String = "Other",
    placeholder: String = "enter here",
    isMandatory: Bool = true,
    isExclusive: Bool = false,
    detailText: String = "",
    value: String = ""
  ) {
    self.isShowOtherField = isShowOtherField
    self.otherTitle = otherTitle
    self.placeholder = placeholder
    self.isMandatory = isMandatory
    self.isShowOtherCell = isShowOtherCell
    self.isExclusive = isExclusive
    self.detailText = detailText
    self.value = value
  }
}

/// Subclass of `ORKQuestionStep` which includes the configuration of `OtherChoice`.
class QuestionStep: ORKQuestionStep {

  /// Instance of `OtherChoice` configuration.
  lazy var otherChoice = OtherChoice()

  init(
    identifier: String,
    title: String?,
    question: String,
    answer: ORKAnswerFormat,
    otherChoice: OtherChoice
  ) {
    super.init(identifier: identifier)
    self.title = title
    self.question = question
    self.answerFormat = answer
    self.otherChoice = otherChoice
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    fatalError("init(coder:) has not been implemented")
  }

}

class TextChoiceQuestionController: ORKQuestionStepViewController {

  ///  Table View ref from the Super class
  var tableView: UITableView?

  /// Current step
  var questionStep: QuestionStep?

  /// Continue button ref from the Super class
  private var continueBtn: UIButton?

  var answerFormat: ORKTextChoiceAnswerFormat? {
    return questionStep?.answerFormat as? ORKTextChoiceAnswerFormat
  }

  override var result: ORKStepResult? {

    let orkResult = super.result

    guard let identifier = step?.identifier else { return nil }
    let choiceResult = ORKChoiceQuestionResult(identifier: identifier)

    var choices: [Any] = []

    for choice in self.selectedChoices {
      choices.append(choice.value)
    }

    if self.isOtherCellSelected {
      var otherChoiceDict: [String: Any]!
//        otherChoiceDict = ["other": otherChoice.value]
      if self.otherChoice.isShowOtherField {
        if otherChoice.otherChoiceText == "" {
          otherChoiceDict = [
            "other": otherChoice.value,
          ]

        } else {
        otherChoiceDict = [
          "other": otherChoice.value,
          "text": otherChoice.otherChoiceText,
        ]
        }
      } else {
        if otherChoice.otherChoiceText == "" {
        otherChoiceDict = [
          "other": otherChoice.value,
        ]
        } else {
          otherChoiceDict = [
            "other": otherChoice.value,
            "text": otherChoice.otherChoiceText,
          ]
          }
      }
      choices.append(otherChoiceDict as Any)
//      choices.append(otherChoice.value)
    }

    if self.answerFormat?.style == .multipleChoice {
      choiceResult.questionType = .multipleChoice
    } else {
      choiceResult.questionType = .singleChoice
    }

    choiceResult.choiceAnswers = choices
    orkResult?.results = [choiceResult]
    return orkResult

  }

  /// Data sources
  lazy var textChoices: [ORKTextChoice]! = []

  lazy private(set) var selectedChoices: [ORKTextChoice] = []
  lazy var searchChoices: [ORKTextChoice] = []
  lazy var answers: [[String: String]]? = []

  private(set) var isOtherCellSelected = false

  // MARK: - UI

  /// Search bar
  private var searchBar: UISearchBar?

  /// Default font for question
  private let questionFont: UIFont = UIFont.boldSystemFont(ofSize: 25)

  /// Height used for search bar
  private let searchBarHeight: CGFloat = 44

  /// Returns wheather search bar is in editing mode
  lazy private var isSearching = false

  lazy var otherChoice = OtherChoice()

  var isShowSearchBar: Bool {
    if self.otherChoice.isShowOtherCell {
      return self.textChoices.count > 9
    } else {
      return self.textChoices.count > 10
    }
  }

  // Initializers
  override init(step: ORKStep?) {
    super.init(step: step)
  }

  override init(step: ORKStep, result: ORKResult) {
    super.init(step: step, result: result)

    if let stepResult = (result as? ORKStepResult),
      let choiceResult = stepResult.result(forIdentifier: step.identifier)
        as? ORKChoiceQuestionResult,
      let choices = choiceResult.choiceAnswers
    {

      for choice in choices {

        if let choice = choice as? String {
            self.answers?.append(["value": choice])
        } else if let choiceDict = choice as? JSONDictionary {
            if let otherChoice = choiceDict["text"] as? String {
                self.answers?.append(["otherChoiceText": otherChoice])
            } else if let otherChoice = choiceDict["other"] as? String {
                self.answers?.append(["otherValue": otherChoice])
            }
          
        }
      }

    }
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - Lifycycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.stepDidChange()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.tableView?.tableHeaderView = headerViewForAdditionalText()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    UserDefaults.standard.set("", forKey: "isOptionalTextChoice")
    UserDefaults.standard.synchronize()

    if self.answerFormat?.style == .multipleChoice {
      self.tableView?.allowsMultipleSelection = true
    } else {
      self.tableView?.allowsMultipleSelection = false
    }

    tableView?.isHidden = false
    self.tableView?.reloadData()
    self.updateNextOrContinueBtnState()

  }
  
  /// Ready the view
  private func stepDidChange() {
    
    guard let step = self.step as? QuestionStep, isViewLoaded else {
      return
    }
    self.questionStep = step
    self.textChoices = answerFormat?.textChoices ?? []
    
    self.otherChoice = step.otherChoice
    
//    if let indexOfOtherChoiceValue = self.answers?.firstIndex(of: self.otherChoice.value) {
//      self.answers?.remove(at: indexOfOtherChoiceValue)
//    }
    /// Update the selected result here
    if let answers = self.answers {
      for answer in answers {
        if let answerValue = answer["value"], let selectedChoice = self.textChoices.filter({ $0.value as! String == answerValue })
            .first
        {
          self.selectedChoices.append(selectedChoice)
        } else {  // unable to find the answer in textchoices, perhaps other choice was selected
          self.isOtherCellSelected = true
          if let otherChoiceText = answer["otherChoiceText"] {
              self.otherChoice.otherChoiceText = otherChoiceText
          }
        }
      }
      self.answers = nil
    }
    
    // Get the ref of the super class table view
    if let tableView = self.view.allSubViewsOf(type: UITableView.self).first {
      self.tableView = tableView
      tableView.registerCell(cell: TextChoiceCell.self)
      tableView.registerCell(cell: OtherTextChoiceCell.self)
      tableView.isHidden = true
    }
    
    if self.isShowSearchBar {
      self.searchBar = UISearchBar()
      searchBar?.delegate = self
    }
    
    // Try to get the ref of the continue of the next button
    if let nextBtn = self.view.allSubViewsOf(type: ORKContinueButton.self).last {
      self.continueBtn = nextBtn
      if self.questionStep?.isOptional ?? false {
        self.continueBtn?.setTitle("Next", for: .normal)
      }
      if self.questionStep?.isOptional ?? false {
        self.continueBtn?.setTitle("Next", for: .normal)
      }
      continueBtn?.addTarget(
        self,
        action: #selector(didTapOnDoneOrNextBtn),
        for: .touchUpInside
      )
    }
    
    if super.hasPreviousStep() {
      if navigationItem.leftBarButtonItem == nil {
        let view = UIView(frame: CGRect(x: -15, y: 0, width: 46, height: 36))
        
        //  Filter Button
        let filterButton = addFilterButton()
        filterButton.clipsToBounds = true
        view.addSubview(filterButton)
        filterButton.isExclusiveTouch = true
        
        let barButton = UIBarButtonItem(customView: view)
        navigationItem.leftBarButtonItem = barButton
      }
    }
  }
  
  func addFilterButton() -> UIButton {
    let filterButton = UIButton(type: .custom)
    filterButton.setImage(
      #imageLiteral(resourceName: "leftIconBlue2"),
      for: UIControl.State.normal
    )
    filterButton.addTarget(self, action: #selector(filterAction(_:)), for: .touchUpInside)
    filterButton.frame = CGRect(x: -17, y: 0, width: 46, height: 36)
    return filterButton
  }
      
  @IBAction func filterAction(_: UIBarButtonItem) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "TextChoiceQuestion BackButton"
    ])
    super.goBackward()
  }
        
  // MARK: - UI

  /// Header View of the question displayed in the Table View section.
  private func getQuestionHeaderView() -> UIView {
    let newHeaderView = UIView()
    let questionLbl = UILabel()

    UI: do {
      questionLbl.font = questionFont
      questionLbl.text = self.questionStep?.question
      questionLbl.textColor = .black
      questionLbl.textAlignment = .left
      questionLbl.numberOfLines = 0
      newHeaderView.backgroundColor = .white
      newHeaderView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      newHeaderView.layer.cornerRadius = 10
      newHeaderView.clipsToBounds = true
    }

    layout: do {

      newHeaderView.addSubview(questionLbl)
      questionLbl.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate(
        [
          questionLbl.topAnchor.constraint(
            equalTo: newHeaderView.topAnchor,
            constant: 12
          ),
          questionLbl.leadingAnchor.constraint(
            equalTo: newHeaderView.leadingAnchor,
            constant: 12
          ),
          questionLbl.trailingAnchor.constraint(
            equalTo: newHeaderView.trailingAnchor,
            constant: -12
          ),
        ])

      newHeaderView.sizeToFit()
    }

    if isShowSearchBar {
      addSearchBar(on: newHeaderView, below: questionLbl)
    }

    return newHeaderView
  }

  /// Table Header View
  private func headerViewForAdditionalText() -> UIView? {

    guard let text = self.questionStep?.text, let tableView = self.tableView else { return nil }

    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))

    let textLabel = UILabel()
    textLabel.text = text
    textLabel.textAlignment = .left
    textLabel.numberOfLines = 2
    textLabel.font = UIFont.systemFont(ofSize: 17)
    textLabel.backgroundColor = UIColor.clear
    textLabel.textColor = UIColor.black

    headerView.addSubview(textLabel)

    textLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate(
      [
        textLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 8),
        textLabel.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -16),
        textLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      ])

    return headerView

  }

  private func addSearchBar(on newHeaderView: UIView, below questionLbl: UILabel) {

    guard let searchBar = self.searchBar else { return }

    searchBar.frame = CGRect()
    searchBar.searchBarStyle = UISearchBar.Style.minimal
    searchBar.placeholder = " Search"
    searchBar.sizeToFit()
    searchBar.showsCancelButton = false
    searchBar.returnKeyType = .done
    searchBar.enablesReturnKeyAutomatically = false

    layout: do {

      newHeaderView.addSubview(searchBar)
      searchBar.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate(
        [
          searchBar.trailingAnchor.constraint(
            equalTo: newHeaderView.trailingAnchor,
            constant: -5
          ),
          searchBar.leadingAnchor.constraint(
            equalTo: newHeaderView.leadingAnchor,
            constant: 5
          ),
          searchBar.topAnchor.constraint(equalTo: questionLbl.bottomAnchor, constant: 10),
          searchBar.bottomAnchor.constraint(
            lessThanOrEqualTo: newHeaderView.bottomAnchor,
            constant: -12
          ),
          searchBar.heightAnchor.constraint(equalToConstant: self.searchBarHeight),
        ])
    }

  }

  // MARK: - Utils

  /// Inform if it's last cell of tableView, Other option cell.
  ///
  /// - Parameter indexPath: Indexpath of the tableView cell to check.
  /// - Returns: A Bool value indicating if it's Other cell indexPath or not.
  private func isLastCell(indexPath: IndexPath) -> Bool {
    if (indexPath.row == self.textChoices.count && !isSearching)
      || (indexPath.row == self.searchChoices.count && isSearching)
    {
      return true
    } else {
      return false
    }
  }

  /// Updates the SelectedChoices collection from options on tableView .
  ///
  /// - Parameter choice: Choice of the option selected by user.
  /// - Parameter isSelected: This indicate wheather to add choice or remove.
  private func updateSelectedChoice(choice: ORKTextChoice?, didSelected: Bool) {

    func updateForSingleSelection() {
      self.selectedChoices.removeAll()
      guard choice != nil else { return }  // mil for OtherCell selection, remove all the choices selected
      self.selectedChoices.append(choice!)
    }

    @discardableResult
    func removeOtherChoiceIfExclusive() -> Bool {
      if (self.otherChoice.isExclusive && self.isOtherCellSelected)
        || (choice?.exclusive ?? false && isOtherCellSelected)
      {
        self.isOtherCellSelected = false
        self.tableView?.reloadData()
        return true
      }
      return false
    }

    func removeSelectedExclusiveChoices() {
      let exclusiveSelectedChoices = self.selectedChoices.filter({ $0.exclusive == true })
      if exclusiveSelectedChoices.count > 0 {
        updateForSingleSelection()
        self.tableView?.reloadData()
      }
    }

    func updateForMultipleSelection() {

      guard let choice = choice else {  // Other choice
        if self.otherChoice.isExclusive {
          self.selectedChoices.removeAll()
        }
        removeSelectedExclusiveChoices()
        return
      }

      if choice.exclusive {
        if didSelected {
          updateForSingleSelection()  // Make it behave like single selection
          if !removeOtherChoiceIfExclusive() {
            self.tableView?.reloadData()
          }
          return
        }
      } else {
        removeSelectedExclusiveChoices()
        removeOtherChoiceIfExclusive()
      }

      if let choiceIndex = self.selectedChoices.firstIndex(of: choice) {
        if !(didSelected) {
          self.selectedChoices.remove(at: choiceIndex)
        }
      } else if didSelected {
        self.selectedChoices.append(choice)
      }
    }

    guard self.tableView != nil else { return }

    switch self.tableView!.allowsMultipleSelection {

    case true:
      updateForMultipleSelection()

    case false:
      updateForSingleSelection()

    }

  }

  private func isChoiceSelected(choice: ORKTextChoice) -> Bool {
    if self.selectedChoices.firstIndex(of: choice) != nil {
      return true
    }
    return false
  }

  override func goBackward() {
    super.goBackward()
  }

  override func skipForward() {
    NotificationCenter.default.post(name: Notification.Name("GoForward"), object: nil)

    self.answers = []
    self.selectedChoices = []
    self.isOtherCellSelected = false
    super.skipForward()
  }

  override func goForward() {
    if self.otherChoice.otherChoiceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      self.isOtherCellSelected,
      self.otherChoice.isMandatory
    {

      let alertVC = UIAlertController(
        title: "Answer required",
        message: "Please fill out the text field too.",
        preferredStyle: .alert
      )

      let okAction = UIAlertAction(title: "Ok", style: .default) { [unowned self] (_) in
        alertVC.dismiss(animated: true, completion: nil)
        if let otherCell = self.tableView?.cellForRow(
          at: IndexPath(row: self.textChoices.count, section: 0)
        ) as? OtherTextChoiceCell {
          otherCell.otherField.becomeFirstResponder()
        }
        self.updateNextOrContinueBtnState()
      }

      alertVC.addAction(okAction)
      self.present(alertVC, animated: true, completion: nil)

      updateNextOrContinueBtnState()
    } else {
      NotificationCenter.default.post(name: Notification.Name("GoForward"), object: nil)

      super.goForward()
    }

  }

  @objc func didTapOnDoneOrNextBtn(_ sender: UIButton) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "TextChoice Done/Next"
    ])
    // Next or done button pressed.
  }

  private func didTapOnOtherCell(didSelect: Bool) {

    if didSelect {

      self.isOtherCellSelected = true
      updateSelectedChoice(choice: nil, didSelected: true)
      self.tableView?.reloadData()

      if isSearching {
        view.endEditing(true)  // Will be handled in search bar end editing delegate
      } else {
        let otherCellIndex = IndexPath(row: self.textChoices.count, section: 0)
        let cell = self.tableView?.cellForRow(at: otherCellIndex) as? OtherTextChoiceCell
        if self.otherChoice.isShowOtherField, cell?.otherField.text == "" {
          cell?.otherField.becomeFirstResponder()
        }
      }

    } else {
      self.isOtherCellSelected = false
      self.tableView?.reloadData()
    }

  }

  private func updateNextOrContinueBtnState() {

    if self.selectedChoices.count > 0 || self.isOtherCellSelected {
      self.continueBtn?.isEnabled = true
      self.continueBtn?.isUserInteractionEnabled = true
    } else {
      self.continueBtn?.isEnabled = false
      self.continueBtn?.isUserInteractionEnabled = false
    }

  }

}

extension TextChoiceQuestionController: UITableViewDataSource, UITableViewDelegate {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // Return by adding 1 row extra for other cell
    if isSearching {
      return (self.otherChoice.isShowOtherCell)
        ? self.searchChoices.count + 1 : self.searchChoices.count
    } else {
      return (self.otherChoice.isShowOtherCell)
        ? self.textChoices.count + 1 : self.textChoices.count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    // If it's last cell, return other cell : Perhaps, other option
    if isLastCell(indexPath: indexPath) {
      let cell =
        tableView.dequeueReusableCell(
          withIdentifier: OtherTextChoiceCell.reuseIdentifier,
          for: indexPath
        )
        as! OtherTextChoiceCell

      cell.delegate = self
      cell.otherField.text = self.otherChoice.otherChoiceText
      cell.otherField.placeholder = otherChoice.placeholder
      cell.detailedTextLbl.text = otherChoice.detailText
      cell.titleLbl.text = self.otherChoice.otherTitle

      if self.isOtherCellSelected {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        cell.didSelected = true

        if self.otherChoice.isShowOtherField {
          cell.updateOtherView(isShow: true)
        } else {
          cell.updateOtherView(isShow: false)
        }
      } else {
        cell.didSelected = false
        cell.updateOtherView(isShow: false)
      }

      return cell
    }

    if let cell = tableView.dequeueReusableCell(
      withIdentifier: TextChoiceCell.reuseIdentifier,
      for: indexPath
    ) as? TextChoiceCell {

      var choice: ORKTextChoice!

      if isSearching {
        choice = self.searchChoices[indexPath.row]
      } else {
        choice = self.answerFormat?.textChoices[indexPath.row]
      }
      cell.titleLbl.text = choice.text
      cell.detailedTextLbl.text = choice.detailText ?? ""
      if self.isChoiceSelected(choice: choice) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        cell.didSelected = true
      }

      return cell
    }

    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    if isLastCell(indexPath: indexPath) {
      /// When user selects Other option
      didTapOnOtherCell(didSelect: true)
      /// This will reload the tableView and indexpath will have diff cell
      self.delegate?.stepViewControllerResultDidChange(self)
      updateNextOrContinueBtnState()
      return
    }

    if let cell = tableView.cellForRow(at: indexPath) as? TextChoiceCell {
      cell.didSelected = true
      if isSearching {
        updateSelectedChoice(choice: self.searchChoices[indexPath.row], didSelected: true)
      } else {
        updateSelectedChoice(choice: self.textChoices[indexPath.row], didSelected: true)
      }
      self.delegate?.stepViewControllerResultDidChange(self)
      updateNextOrContinueBtnState()
    }

  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {

    if isLastCell(indexPath: indexPath) {
      didTapOnOtherCell(didSelect: false)
    }

    if let cell = tableView.cellForRow(at: indexPath) as? TextChoiceCell {
      if isSearching {
        updateSelectedChoice(choice: self.searchChoices[indexPath.row], didSelected: false)
      } else {
        updateSelectedChoice(choice: self.textChoices[indexPath.row], didSelected: false)
      }
      cell.didSelected = false
    }

    self.delegate?.stepViewControllerResultDidChange(self)
    updateNextOrContinueBtnState()
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return getQuestionHeaderView()
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

    var height: CGFloat = 70
    let verticalPadding: CGFloat = (self.isShowSearchBar) ? 80 : 24
    let horPadding: CGFloat = 24
    if let question = self.questionStep?.question {
      height =
        question.estimatedLabelHeight(
          labelWidth: tableView.frame.width - horPadding,
          font: self.questionFont
        )
        + verticalPadding
    }

    return height
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
}

extension TextChoiceQuestionController: OtherTextChoiceCellDelegate {

  func didEndEditing(with text: String?) {
    /// Use the text
    self.otherChoice.otherChoiceText = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    self.tableView?.setContentOffset(CGPoint(x: 0, y: -1), animated: true)
  }
}

// MARK: - Search Bar Delegate
extension TextChoiceQuestionController: UISearchBarDelegate {

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    guard let textChoices = self.textChoices else { return }

    if searchText == "" {
      self.searchChoices = textChoices
    } else {
      self.searchChoices = textChoices.filter({
        $0.text.localizedLowercase.contains(searchText.localizedLowercase)
      })
    }
    self.tableView?.reloadData()
  }

  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    self.searchChoices = textChoices
    self.navigationController?.navigationBar.prefersLargeTitles = false
    var tableHeaderViewHeight = self.tableView?.tableHeaderView?.frame.height ?? 0
    tableHeaderViewHeight = (tableHeaderViewHeight == 0) ? 35 : tableHeaderViewHeight
    self.tableView?.setContentOffset(CGPoint(x: 0, y: tableHeaderViewHeight), animated: true)  // change the table view content offset
    self.isSearching = true

  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    navigationController?.navigationBar.prefersLargeTitles = false
    searchBar.text = ""
    self.searchChoices = []
    self.isSearching = false

    self.tableView?.reloadData()

    if self.otherChoice.isShowOtherCell {
      let otherCellIndex = IndexPath(row: self.textChoices.count, section: 0)
      self.tableView?.scrollToRow(at: otherCellIndex, at: .bottom, animated: true)
    }

    if !self.isOtherCellSelected {
      self.tableView?.setContentOffset(CGPoint(x: 0, y: -1), animated: true)
    } else {
      let totalSec = 30 * self.textChoices.count
      let deadlineTime = DispatchTime.now() + .milliseconds(totalSec)
      DispatchQueue.main.asyncAfter(deadline: deadlineTime) {

        if let cell = self.tableView?.cellForRow(
          at: IndexPath(row: self.textChoices.count, section: 0)
        ) as? OtherTextChoiceCell {
          if (cell.otherField?.text?.isEmpty ?? true) && self.otherChoice.isShowOtherField {
            cell.otherField.becomeFirstResponder()
          } else {
            self.tableView?.setContentOffset(CGPoint(x: 0, y: -1), animated: true)
          }
        }
      }
    }
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    view.endEditing(true)
  }
}
