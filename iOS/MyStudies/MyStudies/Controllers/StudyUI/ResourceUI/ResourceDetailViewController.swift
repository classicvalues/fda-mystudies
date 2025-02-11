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

import MessageUI
import SafariServices
import UIKit
import WebKit
import FirebaseAnalytics
import Reachability

class ResourceDetailViewController: UIViewController {

  // MARK: - Outles
  @IBOutlet var webView: WKWebView!
  @IBOutlet var bottomToolBar: UIToolbar!
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  @IBOutlet var shareButton: UIBarButtonItem!

  // MARK: - Properties
  var requestLink: String?
  var type: String?
  var htmlString: String?
  var resource: Resource?
  private var reachability: Reachability!

  /// Resource converted from HTML string and saved in Cache directory.
  var tempResourceFilePath: URL?

  private var isFileAvailable = false

  static var resouceDirectory: String {
    return "Resources" + "/" + (Study.currentStudy?.studyId ?? "")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupNotifiers()
    self.hidesBottomBarWhenPushed = true
    self.addBackBarButton()
    self.title = resource?.title
    setNavigationBarColor()
  }
    
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    webView.navigationDelegate = self
    webView.contentScaleFactor = 1.0
    loadWebView()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    DispatchQueue.main.async {
      if let tempResource = self.tempResourceFilePath {
        AKUtility.deleteFile(from: tempResource)
      }
    }
    webView.navigationDelegate = nil
  }
    
    // MARK: - Utility functions
    func setupNotifiers() {
        NotificationCenter.default.addObserver(self, selector:#selector(reachabilityChanged(note:)),
                                               name: Notification.Name.reachabilityChanged, object: nil);
        
        do {
            self.reachability = try Reachability()
            try self.reachability.startNotifier()
        } catch(let error) { }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .cellular:
            setOnline()
            break
        case .wifi:
            setOnline()
            break
        case .none:
            setOffline()
            break
        case .unavailable:
            setOffline()
            break
        }
    }
    
    func setOffline() {
        shareButton.isEnabled = false
    }
    
    func setOnline() {
        shareButton.isEnabled = true
    }

  // MARK: - UI
  fileprivate func loadWebView() {

    if let resourceLink = self.resource?.file?.link {
      if self.resource?.file?.mimeType == .pdf {
        if self.resource?.file?.localPath == "BundlePath" {
          if let path = Bundle.main.path(
            forResource: resourceLink,
            ofType: ".pdf"
          ) {
            isFileAvailable = true
            self.loadWebViewWithPath(path: path)
          }
        } else if let resourceLink = self.resource?.file?.link,
          let resourceURL = URL(string: resourceLink)
        {
          activityIndicator.startAnimating()
          activityIndicator.isHidden.toggle()
//          let fileURL = checkIfFileExists(pdfNameFromUrl: "\(resource?.file?.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "").pdf")
//          let fileURL = checkIfFileExists(pdfNameFromUrl: "\(resource?.file?.name ?? "").pdf")
//          if let url = fileURL {
//            webView.loadFileURL(url, allowingReadAccessTo: url)
//            self.isFileAvailable = true
//            self.webView.isHidden = false
//          } else {
          self.webView.isHidden = false
          self.webView.load(URLRequest(url: resourceURL))
//          }
        }
      } else if self.resource?.file?.mimeType == .txt,
        let resourceHtmlString = self.resource?.file?.link
      {
        let detailText = resourceHtmlString
        webView.allowsBackForwardNavigationGestures = false
        var resourceHtmlString2 = resourceHtmlString.stringByDecodingHTMLEntities
        let regex = "<[^>]+>"
        if detailText.stringByDecodingHTMLEntities.range(of: regex, options: .regularExpression) == nil {
          if let valReConversiontoHTMLfromHTML = detailText.stringByDecodingHTMLEntities.htmlToAttriString?.attriString2Html {
            
            if let attributedText =
                valReConversiontoHTMLfromHTML.stringByDecodingHTMLEntities.htmlToAttriString, attributedText.length > 0 {
              resourceHtmlString2 = attributedText.attriString2Html ?? ""
            } else if let attributedText =
                        resourceHtmlString2.htmlToAttriString?.attriString2Html?.stringByDecodingHTMLEntities.htmlToAttriString,
                      attributedText.length > 0 {
              resourceHtmlString2 = attributedText.attriString2Html ?? ""
            } else {
              resourceHtmlString2 = resourceHtmlString
            }
          } else {
            resourceHtmlString2 = resourceHtmlString
          }
        }
        
        webView.loadHTMLString(
          WebViewController.headerString + resourceHtmlString2,
          baseURL: nil
        )
        
      } else if let htmlString = self.htmlString {
        webView.allowsBackForwardNavigationGestures = false
        webView.loadHTMLString(WebViewController.headerString + htmlString, baseURL: nil)
      } else if let requestLink = self.requestLink,
        let url = URL(string: requestLink)
      {
        self.webView.load(URLRequest(url: url))
      }
    }
  }

  // MARK: - UI Utils.
  /// To Load web page with `URL` string path.
  /// - Parameter path: Path of the url.
  func loadWebViewWithPath(path: String) {

    guard
      let url: URL = URL(
        string: path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
      )
    else { return }
    let urlRequest = URLRequest(url: url)

    webView?.allowsBackForwardNavigationGestures = true
    _ = webView?.load(urlRequest)

  }

  func loadWebViewWithData(data: Data) {

    webView.allowsBackForwardNavigationGestures = true
    self.webView.load(
      data,
      mimeType: "application/pdf",
      characterEncodingName: "UTF-8",
      baseURL: URL(fileURLWithPath: "")
    )
  }

  // MARK: - Button Actions

  @IBAction func cancelButtonClicked(_ sender: Any) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "ResourceDetail Cancel"
    ])
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func buttonActionForward(_ sender: UIBarButtonItem) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "ResourceDetail Share"
    ])
    self.shareResource { [weak self] (status) in
      if !status {
        self?.view.makeToast(kResourceShareError)
      }
    }
  }

  @IBAction func buttonActionBack(_ sender: UIBarButtonItem) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "ResourceDetail Back"
    ])
    if webView.canGoBack {
      webView.goBack()
    } else if webView.backForwardList.backList.count == 0 {
      if self.resource?.file?.mimeType != .pdf, self.resource?.file?.mimeType != .txt,
         let htmlString = self.requestLink {
        webView.loadHTMLString(WebViewController.headerString + htmlString, baseURL: nil)
      }
    }
  }

  @IBAction func buttonActionGoForward(_ sender: UIBarButtonItem) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "ResourceDetail GoForward"
    ])
    if webView.canGoForward {
      webView.goForward()
    }
  }

}

extension ResourceDetailViewController: WKNavigationDelegate {

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
    if self.resource?.file?.mimeType == .pdf, let url = webView.url, !isFileAvailable {
      savePdf(for: url)
    } else {
      self.activityIndicator.stopAnimating()
    }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
    self.view.makeToast(error.localizedDescription)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)
  ) {
    switch navigationAction.navigationType {
    case .linkActivated:
      if navigationAction.targetFrame == nil {
        webView.load(navigationAction.request)
      }
    default:
      break
    }
    self.activityIndicator.startAnimating()
    decisionHandler(.allow)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
  ) {

    switch navigationResponse.response {

    case let response as HTTPURLResponse:
      if self.resource?.file?.mimeType == .pdf,
        response.statusCode == HTTPError.notFound.rawValue
      {
        self.presentDefaultAlertWithError(
          error: ApiError(code: .notFound),
          animated: true,
          action: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
          },
          completion: nil
        )
        self.activityIndicator.stopAnimating()
        decisionHandler(.cancel)
      } else {
        decisionHandler(.allow)
      }

    default:
      decisionHandler(.allow)
    }
  }
}

// MARK: - Mail Compose Delegate
extension ResourceDetailViewController {

  func shareResource(completion: @escaping (_ status: Bool) -> Void) {
    let resourceLink = self.resource?.file?.link

    if let pathType = self.resource?.file?.localPath,
      pathType == "BundlePath",
      let path = resourceLink
    {
      if let fileURL = Bundle.main.url(
        forResource: path,
        withExtension: "pdf"
      ) {
        attachResource(from: fileURL)
        completion(true)
      }
    } else if self.resource?.file?.mimeType == .pdf,
      isFileAvailable, let link = resourceLink,
              let path = URL.init(string: link),
//      let documentURL = checkIfFileExists(pdfNameFromUrl: "\(resource?.file?.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "").pdf")
              let documentURL = sharePdf(for:path)
    {
      attachResource(from: documentURL)
      completion(true)
    } else if let resourceHTML = resourceLink,
      self.resource?.file?.mimeType != .pdf
    {
      let pdfData = webView.renderSelfToPdfData(htmlString: resourceHTML.stringByDecodingHTMLEntities)
      if let tempPath = tempResourceFilePath {
        attachResource(from: tempPath)
        completion(true)
      } else {
//        let valName = self.resource?.file?.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "Resource"
        let valName = self.resource?.file?.name ?? "Resource"
        ResourceDetailViewController.saveTempPdf(from: pdfData, name:
                                                  valName) {
          [weak self] (url) in
          self?.tempResourceFilePath = url
          if let tempPath = url {
            self?.attachResource(from: tempPath)
            completion(true)
          } else {
            completion(false)
          }
        }
      }
    } else {
      completion(false)
    }

  }

  func attachResource(from url: URL) {

    var items: [Any] = [url]
    let fileTitle = self.resource?.title ?? ""
    items.insert(fileTitle, at: 0)
    let activityController = UIActivityViewController(
      activityItems: items,
      applicationActivities: nil
    )
    present(activityController, animated: true)
  }

}

extension ResourceDetailViewController {

  func savePdf(for url: URL) {

    DispatchQueue.global(qos: .background).async { [weak self] in

      let pdfData = try? Data(contentsOf: url)
//      let pdfNameFromUrl = "\(self?.resource?.file?.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "").pdf"
      let pdfNameFromUrl = "\(self?.resource?.file?.name ?? "").pdf"
      let actualPath = AKUtility.cacheDirectoryPath.appendingPathComponent(pdfNameFromUrl)
      do {
        try pdfData?.write(to: actualPath, options: .atomic)
        AKUtility.moveFileToDocuments(
          fromUrl: actualPath,
          toDirectory: ResourceDetailViewController.resouceDirectory,
          withName: pdfNameFromUrl
        )
        self?.isFileAvailable = true
        DispatchQueue.main.async {
          self?.activityIndicator.stopAnimating()
          self?.webView.loadHTMLString("", baseURL: nil)
          self?.webView.evaluateJavaScript("document.body.remove()")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self?.loadWebView()
          }
        }
      } catch {
        Logger.sharedInstance.error(error)
      }
    }
  }
    
  func sharePdf(for url: URL) -> URL? {
      let pdfData = try? Data(contentsOf: url)
      let pdfNameFromUrl = "\(resource?.file?.name ?? "").pdf"
      let actualPath = AKUtility.cacheDirectoryPath.appendingPathComponent(pdfNameFromUrl)
      do {
          try pdfData?.write(to: actualPath, options: .atomic)
          return actualPath
      } catch {
          Logger.sharedInstance.error(error)
            return nil
      }
      return nil
  }

  static func saveTempPdf(
    from data: Data,
    name: String,
    completion: @escaping (_ url: URL?) -> Void
  ) {
    DispatchQueue.global(qos: .background).async {
//      let pdfNameFromUrl = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "" + ".pdf"
      let pdfNameFromUrl = name + ".pdf"
      let tempPath = AKUtility.cacheDirectoryPath.appendingPathComponent(pdfNameFromUrl)
      do {
        try data.write(to: tempPath, options: .atomic)
        DispatchQueue.main.async {
          completion(tempPath)
        }
      } catch {
        Logger.sharedInstance.error(error)
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
  }

  func checkIfFileExists(pdfNameFromUrl: String) -> URL? {
    let fileExist = AKUtility.checkFileExistAt(
      directory: ResourceDetailViewController.resouceDirectory,
      filename: pdfNameFromUrl
    )
    if fileExist.exist {
      return fileExist.filepath
    } else {
      return nil
    }
  }

}
