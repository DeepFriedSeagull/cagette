
/**
 * Shared entities between neko and js
 */
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
	contractId : Int,
	price : Float,
	vat : Float,
	vatValue : Float,			//montant de la TVA inclue dans le prix
	contractTax : Float, 		//pourcentage de commission défini dans le contrat
	contractTaxName : String,	//label pour la commission : ex: "frais divers"
	desc : String
}
@:keep
enum ProductType {
	CTVegetable;
	CTCheese;
	CTChicken;
	CTFruit;
	CTBread;
	CTMilk;
	CTEggs;
	CTHoney;
	CTKiwi;
	CTJuice;
	CTApple;
}