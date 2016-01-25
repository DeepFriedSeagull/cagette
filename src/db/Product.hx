package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Product
 */
class Product extends Object
{
	public var id : SId;
	public var name : SString<128>;	
	public var ref : SNull<SString<32>>;	//référence produit
	
	@:relation(contractId)
	public var contract : Contract;
	
	//prix TTC
	public var price : SFloat;
	public var vat : SFloat;
	
	public var desc : SNull<SText>;
	public var stock : SNull<SFloat>; //if qantity can be float, stock should be float
	
	public var type : SInt;	//icones
	@:relation(imageId)
	public var image : SNull<sugoi.db.File>;
	
	public var hasFloatQt:SBool; //this product can be ordered in "float" quantity
	
	public function new() 
	{
		super();
	}
	
	/**
	 * Renvoie l'URL complète d'une image en fonction du type
	 * ou une photo uploadée si elle existe
	 */
	public function getImage() {
		if (image == null) {
			var e = Type.createEnumIndex(ProductType, type);		
			return "/img/"+Std.string(e).substr(2).toLowerCase()+".png";	
		}else {
			return App.current.view.file(image);
		}
		
		
		
	}
	
	override function toString() {
		if (name != null) {
			return name;
		}else {
			return "produit";
		}
		
	}
	
	public function infos():ProductInfo {
		return {
			id : id,
			name : name,
			type : Type.createEnumIndex(ProductType, type),
			image : getImage(),
			contractId : contract.id,
			price : price + contract.computeFees(price),
			vat : vat,
			vatValue: (vat != 0 && vat != null) ? (  this.price - (this.price / (vat/100+1))  )  : null,
			contractTax : contract.percentageValue,
			contractTaxName : contract.percentageName,
			desc : desc,
			categories : Lambda.array(Lambda.map(getCategories(), function(c) return c.id)),
			orderable : this.contract.isUserOrderAvailable(),
			stock : contract.hasStockManagement() ? this.stock : null,
			hasFloatQt : hasFloatQt
		}
	}
	
	public function getCategories() {
		return Lambda.map(db.ProductCategory.manager.search($productId == id, false), function(x) return x.category);
	}
	
	
}

