
import Foundation
class JSONObject {
    var jsonObj: [String:AnyObject] = [:]
    
    init?(_ jsonString: String) {
        let json = jsonString.data(using: String.Encoding.utf8)
        do{
            if let jsonData = try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [String:AnyObject]{
                self.jsonObj = jsonData
           }else{
               return nil
           }
        }catch{
            print(error)
            return nil
        }
    }
    init() {
    }
    func getJSONObject(_ name:String) -> JSONObject?{
        if let newJob = jsonObj[name] as? [String:AnyObject] {
            let job = JSONObject()
            job.jsonObj = newJob
            return job
        }
        else{
            return nil
        }
    }
    func getString(_ name:String) -> String? {
        let an = jsonObj[name]
        if(an as? String != nil){
            return  String(an as! String)
        }
        if((an as? Int) != nil){
            return  String(an as! Int)
        }
        else if((an as? Double) != nil){
             return  String(an as! Double)
        }
        else if((an as? Bool) != nil){
            return  String(an as! Bool)
        }
        else{
            return nil
        }
    }
    func getInt(_ name:String) -> Int? {
        return jsonObj[name] as? Int
    }
    func getBoolean(_ name:String) -> Bool? {
        return jsonObj[name] as? Bool
    }
    func has(_ name:String) -> Bool {
        if (jsonObj[name] != nil) {
            return  true
        }
        else{
            return false
        }
    }
    
    func put(name:String,value:String) {
        jsonObj[name] = value as AnyObject
    }
    func put(name:String,value:Bool) {
        jsonObj[name] = value as AnyObject
    }
    func put(name:String,value:Double) {
        jsonObj[name] = value as AnyObject
    }
    func put(name:String,value:Int) {
        jsonObj[name] = value as AnyObject
    }
    func put(name:String,value:JSONObject) {
        jsonObj[name] = value.jsonObj as AnyObject
    }
    func put(name:String,value:JSONArray) {
        if(value.mode==1){
            jsonObj[name] = value.jsonArr as AnyObject
        }else{
            jsonObj[name] = value.jsonArr2 as AnyObject
        }
    }
    
    func getJSONArray(_ name:String) -> JSONArray? {
        if let res = jsonObj[name] as? [[String:AnyObject]] {
            let jarr = JSONArray(fillWithObject: true)
            jarr.jsonArr = res
            return jarr
        }
        else if let res = jsonObj[name] as? [AnyObject] {
            let jarr = JSONArray(fillWithObject: false)
            jarr.jsonArr2 = res
            return jarr
        }
        else{
            return nil
        }
    }
    func toString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObj, options: []) else {
            return "{}"
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? "{}"
    }
    static func isValidJSON(jsonString:String) -> Bool {
        var res = false
        let json = jsonString.data(using: String.Encoding.utf8)
        do{
            if try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [String:AnyObject] != nil{
                res =  true
            }
            else if try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [[String: Any]] != nil {
                res =  true
            }
        }
        catch {
            
        }
        return res
    }
    static func isValidJsonObj(jobString:String) -> Bool {
        var res = false
        let json = jobString.data(using: String.Encoding.utf8)
        do{
            if try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [String:AnyObject] != nil{
                res =  true
            }
        }
        catch {
            
        }
        return res
    }
    
}








class JSONArray{
    var jsonArr: [[String:AnyObject]] = []
    var jsonArr2: [AnyObject] = []
    
    var mode = 1
    
    init?(_ jsonString: String) {
        let json = jsonString.data(using: String.Encoding.utf8)
        do{
            if let jsonData = try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [[String:AnyObject]]{
                jsonArr = jsonData
                mode = 1
            }
            else if let jsonData2 = try JSONSerialization.jsonObject(with: json!, options: .allowFragments) as? [AnyObject]{
                jsonArr2 = jsonData2
                mode = 2
            }
            else{
                return nil
            }
        }catch{
            print(error)
            return nil
        }
    }
    init(fillWithObject:Bool=true) {
        if(fillWithObject){
            mode = 1
        }
        else{
            mode = 2
        }
    }
    func getJSONObject(_ i:Int) -> JSONObject? {
        if(i>jsonArr.count-1){
            return nil
        }
        else{
            let job = JSONObject()
            job.jsonObj = jsonArr[i]
            return job
        }
    }
    func getString(_ i:Int) -> String? {
        if(i>jsonArr2.count-1){
            return nil
        }
        
       let an = jsonArr2[i]
       if(an as? String != nil){
           return  String(an as! String)
       }
       if((an as? Int) != nil){
           return  String(an as! Int)
       }
       else if((an as? Double) != nil){
            return  String(an as! Double)
       }
       else if((an as? Bool) != nil){
           return  String(an as! Bool)
       }
       else{
           return nil
       }
    }
    func count() -> Int {
        return mode == 1 ? jsonArr.count : jsonArr2.count
        
        /*if(mode==1){
            return jsonArr.count
        }else{
            return jsonArr2.count
        }*/
    }
    func put(job:JSONObject)  {
        jsonArr.append(job.jsonObj)
        
    }
    func put(job:JSONObject, index:Int)  {
        jsonArr.insert(job.jsonObj, at: index)
        
    }
    func put(value:AnyObject)  {
        jsonArr2.append(value)
    }
    func remove(i: Int) {
        if mode == 1{
            if i<jsonArr.count{
                jsonArr.remove(at: i)
            }
        }
        else{
            if i<jsonArr2.count{
                jsonArr2.remove(at: i)
            }
        }
    }
    func append(jarr:JSONArray){
        if mode == 1{
            for i in 0..<jarr.count() {
                jsonArr.append(jarr.jsonArr[i])
            }
        }
        
        
    }
    func toString() -> String {
        if(mode==2){
            guard let data = try? JSONSerialization.data(withJSONObject: jsonArr2, options: []) else {
                return "[]"
            }
            return String(data: data, encoding: String.Encoding.utf8) ?? "[]"
        }
        else{
            guard let data = try? JSONSerialization.data(withJSONObject: jsonArr, options: []) else {
                return "[]"
            }
            return String(data: data, encoding: String.Encoding.utf8) ?? "[]"
        }
    }
}
