package db;
import sys.db.Object;
import sys.db.Types;
/**
 * Commande récurrente d'un produit
 */

class UserContract extends Object
{

	public var id : SId;
	
	@:relation(amapId)
	public var amap : db.Amap;
	public var amapId: SInt;
	
	@formPopulate("populate") @:relation(userId)
	public var user : User;
	public var userId: SInt;
	
	//panier alterné
	@formPopulate("populate") @:relation(userId2)
	public var user2 : SNull<User>;
	
	public var quantity : SInt;
	
	@formPopulate("populateProducts") @:relation(productId)
	public var product : Product;
	
	public var paid : SBool;
	
	//if not null : varying orders
	@:relation(distributionId)
	public var distribution:SNull<db.Distribution>;
	public var distributionId : SNull<SInt>;
	
	public function new() 
	{
		super();
		quantity = 1;
	}
	
	public function populate() {
		return App.current.user.getAmap().getMembersFormElementData();
	}
	
	public function populateProducts() {
		var arr = new Array<{key:String,value:String}>();
		return arr;
		//for( p in produ
	}
	
	
	
	/**
	 * 
	 * @param	distrib
	 * @return	false -> user , true -> user2
	 */
	public function getWhosTurn(distrib:Distribution) {
		if (user2 == null) throw "this contract is not shared";
		
		//compter le nbre de distrib pour ce contrat
		var c = Distribution.manager.count( $contract == product.contract && $date >= product.contract.startDate && $date <= distrib.date);		
		return c%2 == 0;
	}
	
	override public function toString() {
		return quantity + "x" + product.name;
	}
	
}