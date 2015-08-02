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
	
	public var type : SInt;	//icones
	@:relation(imageId)
	public var image : SNull<sugoi.db.File>;
	
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
			return "/file/" + App.current.view.file(image.id) + ".jpg";
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
			price : contract.percentageValue!=null ? price*(contract.percentageValue/100+1) : price, //prix total incluant com de contrat
			vat : vat,
			vatValue: (vat != 0 && vat != null) ? (  this.price - (this.price / (vat/100+1))  )  : null,
			contractTax : contract.percentageValue,
			contractTaxName : contract.percentageName,
			desc : desc,
			categories : Lambda.array(Lambda.map(getCategories(), function(c) return c.id))
		}
	}
	
	public function getCategories() {
		return Lambda.map(db.ProductCategory.manager.search($productId == id, false), function(x) return x.category);
	}
	
	
}

