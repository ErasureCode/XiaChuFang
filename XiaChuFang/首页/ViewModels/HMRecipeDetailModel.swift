//
//  HMRecipeDetailModel.swift
//  XiaChuFang
//
//  Created by 梁航铭 on 2020/8/8.
//  Copyright © 2020 梁航铭. All rights reserved.
//

import Foundation
import Ji

public struct HMPeople {
    var imageUrl: String?
    var authorName: String?
    var authorImageUrl: String?
    var authorText: String?
    var likeNumber: String?
    var time: String?
}

struct HMRecipeDetailModel {
    
    struct HMComment {
        var authorImageUrl: String?
        var authorName: String?
        var authorText: String?
        var likeNumber: String?
    }
    
    var imageUrl: String?
    
    var imageRatio: Float?{
        let items = imageUrl?.split(separator: "_")
        let width = items![1].prefix(while: { (c) -> Bool in return c != "w"})
        let height = items![2].prefix(while: { (c) -> Bool in return c != "h"})
        return Float(height)! / Float(width)!
    }
    var title: String?
    var doneNumber: String?
    var rate: String?
    var collectionNumber: String?
    var viewedNumber: String?
    
    var authorName: String?
    var authorImageUrl: String?
    var createTime: String?
    var isShowIcon: Bool = false
    
    var text: String?
    var gradients = [(String, String)]()
    var steps =  [(String, String, Float)]()
    var smallTip: String?
    
    var comments = [HMComment]()
    var peoples = [HMPeople]()
    
    static func getModel(id: String) -> Self{
        var model = HMRecipeDetailModel()
        
        let url = "https://www.xiachufang.com/recipe/\(id)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let jiDoc = Ji(htmlURL: URL(string: url)!)!
        let title = jiDoc.xPath("//h1[@class='page-title']")!.first?.content!
        
        // 标题
        model.title = title?.trimmingCharacters(in: ["\n", " "])
        
        // 配图
        model.imageUrl = jiDoc.xPath("//div[@class='block recipe-show']")?.first?.xPath("div").first?.xPath("img").first?.attributes["src"]
        
        // 评分，跟做人数
        let span = jiDoc.xPath("//span[@class='number']")!
        if span.count == 2{
            let rate = jiDoc.xPath("//span[@class='number']")![0].content!
            model.rate = "\(rate)综合评分 • "
            model.doneNumber = jiDoc.xPath("//span[@class='number']")![1].content!
        }else if span.count == 1{
            model.doneNumber = jiDoc.xPath("//span[@class='number']")![0].content!
        }

        // 收藏人数，超过一万改成多少万，浏览人数拿不到，自己瞎造一个
        let collectionNumber = jiDoc.xPath("//div[@class='pv']")?.first?.content
        let collectionNumberDouble = Double(collectionNumber?.split(separator: " ")[0] ?? " ")!
        if collectionNumberDouble > 10000.0{
            model.collectionNumber = String.init(format: "%.1f万", (collectionNumberDouble/10000.0))
            model.viewedNumber =  String.init(format: "%.0f万", collectionNumberDouble / 10000.0 * Double(10 + arc4random() % 5))
        }else{
            model.collectionNumber = String(Int(collectionNumberDouble))
            model.viewedNumber =  String(Int(collectionNumberDouble * Double(10 + arc4random() % 5)))
        }
        
        // 创建时间
        let createTime = jiDoc.xPath("//div[@class='time']")?.first?.content
        model.createTime = String(createTime?.split(separator: " ")[1] ?? " ")
    
        // 作者名
        let authorName = jiDoc.xPath("//div[@class='author']")?.first?.content
        model.authorName = authorName?.trimmingCharacters(in: ["\n", " "])
        
        // 作者头像url
        model.authorImageUrl = jiDoc.xPath("//div[@class='author']")?.first?.xPath("a").first?.xPath("img").first?.attributes["src"]
        if let _ = jiDoc.xPath("//a[@class='icon icon-cooker']") {model.isShowIcon = true}
        
        // 正文
        let text = jiDoc.xPath("//div[@class='desc mt30']")?.first?.content
        model.text = text?.trimmingCharacters(in: ["\n", " "])
        
        // 小贴士
        model.smallTip = jiDoc.xPath("//div[@class='tip']")?.first?.content?.trimmingCharacters(in: ["\n", " "])
        
        // 原材料
        let gradNames = jiDoc.xPath("//td[@class='name']")
        let gradUnits = jiDoc.xPath("//td[@class='unit']")
        for i in 0..<gradNames!.count{
            var name = ""
            if gradNames![i].xPath("a").count != 0{
                name = gradNames![i].xPath("a").first!.content!
            }else{
                name = gradNames![i].content!.trimmingCharacters(in: ["\n", " "])
            }
            let unit: String = (gradUnits![i].content?.trimmingCharacters(in: ["\n", " "]))!
            model.gradients.append((name, unit))
        }
        
        // 步骤
        let steps = jiDoc.xPath("//li[@class='container']")!
        for i in 0..<steps.count{
            let text: String = steps[i].xPath("p").first!.content!
            var imageUrl = ""
            var ratio: Float = 0
            if let tmp = steps[i].xPath("img").first?.attributes["src"]{
                imageUrl = tmp
                let items = imageUrl.split(separator: "_")
                
                let width = items[1].prefix(while: { (c) -> Bool in return c != "w"})
                
                let height = items[2].prefix(while: { (c) -> Bool in return c != "h"})
                
                ratio = Float(height)! / Float(width)!
            }
            model.steps.append((text, imageUrl, ratio))
        }
                
        // 评论
        let authorImageUrls = jiDoc.xPath("//div[@class='left']")
        let authorNames = jiDoc.xPath("//div[@class='right-top info']")
        let authorTexts = jiDoc.xPath("//div[@class='right-bottom']")
        let likeNumbers = jiDoc.xPath("//span[@class='digged-number']")
        
        for i in 0..<min((authorTexts ?? []).count, 2){
            let imageUrl = authorImageUrls?[i].xPath("a").first?.xPath("img").first?.attributes["data-src"]
            let name = authorNames?[i].xPath("a").first?.content
            let text = authorTexts?[i].content!.trimmingCharacters(in: ["\n", " "])
            let number = likeNumbers?[i].content
            model.comments.append(HMComment(authorImageUrl: imageUrl, authorName: name, authorText: text, likeNumber: number))
        }
        
        // 大家做的
        let urlPeople = "https://www.xiachufang.com/recipe/\(id)/dishes".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let jiDocPeople = Ji(htmlURL: URL(string: urlPeople)!)!
        
        let descs = jiDocPeople.xPath("//p[@class='desc']")
        let imageUrls = jiDocPeople.xPath("//div[@class='cover']")!
        let times = jiDocPeople.xPath("//p[@class='pure-u-1-2']")!
        let authorNamesP = jiDocPeople.xPath("//div[@class='author clearfix ellipsis']")
        let likes = jiDocPeople.xPath("//span[@class='n-diggs']")
        
        for i in 0..<min(10, jiDocPeople.xPath("//p[@class='desc']")!.count){
            var people = HMPeople()
            people.authorText = descs?[i].content?.trimmingCharacters(in: ["\n", " "])
            people.imageUrl = imageUrls[i].xPath("img").first?.attributes["data-src"]
            people.time = times[i].content
            people.authorName = authorNamesP?[i].xPath("a").first?.attributes["title"]
            people.authorImageUrl = authorNamesP?[i].xPath("a").first?.xPath("img").first?.attributes["data-src"]
            people.likeNumber = likes?[i].content
            
            model.peoples.append(people)
        }
        
        return model
    }
}

