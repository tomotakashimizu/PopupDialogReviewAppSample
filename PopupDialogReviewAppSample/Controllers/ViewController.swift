//
//  ViewController.swift
//  PopupDialogReviewAppSample
//
//  Created by 清水智貴 on 2020/09/25.
//

import UIKit
import NCMB
import SVProgressHUD
import Cosmos
import PopupDialog

class ViewController: UIViewController {
    
    // レビューの表示に必要なReviewクラスの配列を用意
    var reviews = [Review]()
    // レビューの星数の配列
    var reviewRatings = [Double]()
    
    @IBOutlet var reviewCosmosView: CosmosView!
    @IBOutlet var reviewAverageLabel: UILabel!
    @IBOutlet var reviewTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadReviews()
    }
    
    //総和｜全体の各要素を足し合わせるだけ。
    func sum(_ array:[Double])->Double{
        return array.reduce(0,+)
    }
    
    //平均値｜全体の総和をその個数で割る。
    func average(_ array:[Double])->Double{
        return self.sum(array) / Double(array.count)
    }
    
    // レビューを読み込む関数
    func loadReviews() {
        
        guard let currentUser = NCMBUser.current() else {
            // ログインに戻る
            let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            
            // ログインしていない状態の保持(AppDelegateの"isLogin"の宣言より)
            let ud = UserDefaults.standard
            ud.set(false, forKey: "isLogin")
            ud.synchronize()
            
            return
        }
        
        let query = NCMBQuery(className: "Review")
        query?.includeKey("user")
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                // 初期化
                self.reviews = [Review]()
                self.reviewRatings = [Double]()
                
                for reviewObject in result as! [NCMBObject] {
                    // レビューをしたユーザーの情報を取得
                    let user = reviewObject.object(forKey: "user") as! NCMBUser
                    
                    // 退会済みユーザーの投稿を避けるため、activeがfalse以外のモノだけを表示
                    if user.object(forKey: "active") as? Bool != false {
                        
                        let userModel = User(objectId: user.objectId, userName: user.userName)
                        
                        // コメントの文字を取得
                        let text = reviewObject.object(forKey: "text") as! String
                        let starRating = reviewObject.object(forKey: "starRating") as! Double
                        
                        // Reviewクラスに格納
                        let review = Review(user: userModel, reviewText: text, createDate: reviewObject.createDate, reviewRating: starRating)
                        self.reviews.append(review)
                        self.reviewRatings.append(review.reviewRating)
                    }
                }
                
                // 平均算出
                let averageReviewRating = self.average(self.reviewRatings)
                // 四捨五入して小数点第二位まで表示
                let roundAverageReviewRating = round(averageReviewRating * 100) / 100
                // レビューの星数の平均を表示
                self.reviewAverageLabel.text = String(roundAverageReviewRating)
                self.reviewCosmosView.rating = roundAverageReviewRating
                
                // テーブルをリロード
                self.reviewTableView.reloadData()
            }
        })
    }
    
    // レビューのためのアラート表示
    func showCustomDialog(animated: Bool = true) {
        
        // Create a custom view controller
        let ratingVC = RatingViewController(nibName: "RatingViewController", bundle: nil)
        
        // Create the dialog
        let popup = PopupDialog(viewController: ratingVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceDown,
                                tapGestureDismissal: true,
                                panGestureDismissal: false)
        
        // Create first button
        let buttonOne = CancelButton(title: "CANCEL", height: 60) {
            //alertを閉じるだけ
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "RATE", height: 60) {
            
            // Save review
            let object = NCMBObject(className: "Review")
            object?.setObject(NCMBUser.current(), forKey: "user")
            object?.setObject(ratingVC.reviewTextField.text, forKey: "text")
            object?.setObject(ratingVC.cosmosStarRating.rating, forKey: "starRating")
            object?.saveInBackground({ (error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    // 保存したものを表示
                    self.loadReviews()
                }
            })
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        present(popup, animated: animated, completion: nil)
    }
    
    // レビューするボタンを押した時の処理
    @IBAction func showCustomDialogTapped() {
        showCustomDialog()
    }
    
}

//tableViewに関する処理
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func configureTableView() {
        
        reviewTableView.dataSource = self
        reviewTableView.delegate = self
        
        let nib = UINib(nibName: "ReviewTableViewCell", bundle: Bundle.main)
        reviewTableView.register(nib, forCellReuseIdentifier: "Cell")
        
        reviewTableView.tableFooterView = UIView()
        
        // tableViewを可変にする
        reviewTableView.estimatedRowHeight = 120
        reviewTableView.rowHeight = UITableView.automaticDimension
    }
    
    // tableViewの数を決める関数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    // tableViewに表示する内容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ReviewTableViewCell
        
        let user = reviews[indexPath.row].user
        cell.userIdLabel.text = user.userName
        cell.reviewCosmosView.rating = reviews[indexPath.row].reviewRating
        cell.reviewLabel.text = reviews[indexPath.row].reviewText
        
        return cell
    }
}

//showMenu（alert）の処理
extension ViewController {
    
    @IBAction func showMenu() {
        // いつも使っているアラートではなく、.actionSheetを使う
        let alertController = UIAlertController(title: "メニュー", message: "メニューを選択してください。", preferredStyle: .actionSheet)
        
        let signOutAction = UIAlertAction(title: "ログアウト", style: .default) { (action) in
            NCMBUser.logOutInBackground({ (error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    // ログアウト成功
                    let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    
                    // ログインしていない状態の保持(AppDelegateの"isLogin"の宣言より)
                    let ud = UserDefaults.standard
                    ud.set(false, forKey: "isLogin")
                    ud.synchronize()
                }
            })
        }
        let deleteAction = UIAlertAction(title: "退会", style: .default) { (action) in
            
            let alert = UIAlertController(title: "会員登録の解除", message: "本当に退会しますか？退会した場合、再度このアカウントをご利用頂くことができません。", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                // ユーザーのアクティブ状態をfalseに
                if let user = NCMBUser.current() {
                    user.setObject(false, forKey: "active")
                    user.saveInBackground({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            // userのアクティブ状態を変更できたらログイン画面に移動
                            let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                            let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                            UIApplication.shared.keyWindow?.rootViewController = rootViewController
                            
                            // ログイン状態の保持
                            let ud = UserDefaults.standard
                            ud.set(false, forKey: "isLogin")
                            ud.synchronize()
                        }
                    })
                } else {
                    // userがnilだった場合ログイン画面に移動
                    let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    
                    // ログインしていない状態の保持(AppDelegateの"isLogin"の宣言より)
                    let ud = UserDefaults.standard
                    ud.set(false, forKey: "isLogin")
                    ud.synchronize()
                }
            })
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(signOutAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
