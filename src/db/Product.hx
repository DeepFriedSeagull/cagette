package db;
import sys.db.Object;
import sys.db.Types;
/**
 * Product
 */
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
 
 
class Product extends Object
{
	public var id : SId;
	public var name : SString<128>;
	public var type : SInt;
	
	@:relation(contractId)
	public var contract : Contract;
	
	//prix TTC
	public var price : SFloat;
	public var vat : SFloat;
	
	public var desc : SNull<SText>;
	
	public function new() 
	{
		super();
	}
	
	public function getImage() {
		var e = Type.createEnumIndex(ProductType, type);		
		return Std.string(e).substr(2).toLowerCase()+".png";
		
	}
	
	override function toString() {
		if (name != null) {
			return name;
		}else {
			return "produit";
		}
		
	}
	
}

