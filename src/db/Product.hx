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
	
	public function infos():ProductInfo {
		return {
			id : id,
			name : name,
			type : Type.createEnumIndex(ProductType, type),
			contractId : contract.id,
			price : contract.percentageValue!=null ? price*(contract.percentageValue/100+1) : price, //prix total incluant com de contrat
			vat : vat,
			vatValue: (vat != 0 && vat != null) ? (  this.price - (this.price / (vat/100+1))  )  : null,
			contractTax : contract.percentageValue,
			contractTaxName : contract.percentageName,
			desc : desc
		}
	}
	
}

