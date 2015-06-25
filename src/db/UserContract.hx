package db;
import sys.db.Object;
import sys.db.Types;
import Common;
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
	
	/**
	 * Prepare un dataset simple pret pour affichage ou export csv.
	 * Penser à classer par user !
	 */
	public static function prepare(orders:List<db.UserContract>) {
		var out = new Array<UserOrder>();
		
		for (o in orders) {
		
			var x : UserOrder = cast {};
			x.userId = o.user.id;
			x.userName = o.user.getCoupleName();
			x.productId = o.product.id;
			x.productName = o.product.name;
			x.quantity = o.quantity;
			x.subTotal = o.quantity * o.product.price;
			var c = o.product.contract;
			if (c.hasPercentageOnOrders()) {
				x.fees = c.percentageValue * x.subTotal;
				x.percentageName = c.percentageName;
				x.percentageValue = c.percentageValue;
				x.total = x.subTotal + x.fees;
			}else {
				x.total = x.subTotal;
			}
			x.paid = o.paid;
			
			out.push(x);
			
		}
		
		
		return out;
	}
	
}