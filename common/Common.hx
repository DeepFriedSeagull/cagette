/**
 * Shared entities between neko and js
 */

//utilisé dans le shop
@:keep
typedef Order = {
	token:String,
	products:Array<{productId:Int,quantity:Int}>
}

@:keep
typedef ProductInfo = {
	id : Int,
	name : String,
	type : ProductType,
	image : Null<String>,
	contractId : Int,
	price : Float,
	vat : Float,
	vatValue : Float,			//montant de la TVA inclue dans le prix
	contractTax : Float, 		//pourcentage de commission défini dans le contrat
	contractTaxName : String,	//label pour la commission : ex: "frais divers"
	desc : String,
	categories : Array<Int>,	//tags
}

@:keep
enum ProductType {
	CTVegetable;
	CTCheese;
	CTChicken;
	CTUnknown;
	CTWine;
	CTMeat;
	CTEggs;
	CTHoney;
	CTFish;
	CTJuice;
	CTApple;
	CTBread;
	CTYahourt;
	
}

/**
 * datas used with the "tagger" ajax class
 */
@:keep
typedef TaggerInfos = {
	products:Array<{product:ProductInfo,categories:Array<Int>}>,
	categories : Array<{id:Int,categoryGroupName:String,color:String,tags:Array<{id:Int,name:String}>}>, //groupe de categories + tags
}

/**
 * Links in navbars for plugin
 */
typedef Link = {
	var link:String;
	var name:String;
}

typedef UserOrder = {
	id:Int,
	userId:Int,
	userName:String,
	
	productId:Int,
	productRef:String,
	productName:String,
	productPrice:Float,
	productImage:String,
	
	quantity:Int,
	subTotal:Float,
	fees:Float,
	percentageName:String,
	percentageValue:Float,
	total:Float,
	paid:Bool,
	canModify:Bool,
	
	contractId:Int,
	contractName:String,
}
