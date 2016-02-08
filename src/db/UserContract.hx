package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * a product order 
 */
class UserContract extends Object
{

	public var id : SId;
	
	@formPopulate("populate") @:relation(userId)
	public var user : User;
	#if neko
	public var userId: SInt;
	#end
	
	//panier alterné
	@formPopulate("populate") @:relation(userId2)
	public var user2 : SNull<User>;
	
	public var quantity : SFloat;
	
	@formPopulate("populateProducts") @:relation(productId)
	public var product : Product;
	#if neko
	public var productId : SInt;
	#end
	
	public var paid : SBool;
	
	//if not null : varying orders
	@:relation(distributionId)
	public var distribution:SNull<db.Distribution>;
	#if neko
	public var distributionId : SNull<SInt>;
	#end
	
	public var date : SDateTime;
	
	public function new() 
	{
		super();
		quantity = 1;
		paid = false;
		date = Date.now();
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
	 */
	public static function prepare(orders:List<db.UserContract>):Array<UserOrder> {
		var out = new Array<UserOrder>();
		var orders = Lambda.array(orders);
		
		//order by lastname
		orders.sort(function(a, b) {
			if (a.user.lastName+a.user.id > b.user.lastName+b.user.id ) {
				return 1;
			}
			if (a.user.lastName+a.user.id < b.user.lastName+b.user.id ) {
				return -1;
			}
			return 0;
		});
		
		for (o in orders) {
		
			var x : UserOrder = cast { };
			x.id = o.id;
			x.userId = o.user.id;
			x.userName = o.user.getCoupleName();
			
			x.productId = o.product.id;
			x.productRef = o.product.ref;
			x.productName = o.product.name;
			x.productPrice = o.product.price;
			x.productImage = o.product.getImage();
			
			x.quantity = o.quantity;
			x.subTotal = o.quantity * o.product.price;
			var c = o.product.contract;
			
			if (c.hasPercentageOnOrders()) {
				x.fees = c.computeFees(x.subTotal);
				x.percentageName = c.percentageName;
				x.percentageValue = c.percentageValue;
				x.total = x.subTotal + x.fees;
			}else {
				x.total = x.subTotal;
			}
			x.paid = o.paid;
			
			x.contractId = c.id;
			x.contractName = c.name;
			x.canModify = o.canModify(); 
			
			out.push(x);
			
		}
		
		
		return out;
	}
	
	/**
	 * On peut modifier si ça na pas deja été payé + commande encore ouvertes
	 */
	function canModify():Bool {
	
		var can = false;
		if (this.product.contract.type == db.Contract.TYPE_VARORDER) {
			
			if (this.distribution.orderStartDate == null) {
				can = true;
			}else {
				var n = Date.now().getTime();
				can = n > this.distribution.orderStartDate.getTime() && n < this.distribution.orderEndDate.getTime();
				
			}
			
			
		}else {
		
			can = this.product.contract.isUserOrderAvailable();
			
		}
		
		return can && !this.paid;
		
	}
	
	/**
	 * Créer une commande
	 * 
	 * @param	quantity
	 * @param	productId
	 */
	public static function make(user:db.User, quantity:Float, productId:Int, ?distribId:Int,?paid:Bool) {
		
		//checks
		if (quantity <= 0) return;
		if (distribId != null) {
			var d = db.Distribution.manager.get(distribId);
			if (d.date.getTime() < Date.now().getTime()) throw "Impossible de modifier une commande pour une date de livraison échue. (d"+d.id+")";	
		}
		
		
		//vérifie si il n'y a pas de commandes existantes avec les memes paramètres
		var prevOrders = new List<db.UserContract>();
		
		if (distribId == null) {
			prevOrders = db.UserContract.manager.search($productId==productId && $user==user, true);
		}else {
			prevOrders = db.UserContract.manager.search($productId==productId && $user==user && $distributionId==distribId, true);
		}
		
		var o = new db.UserContract();
		o.productId = productId;
		o.quantity = quantity;
		o.user = user;
		if (paid != null) o.paid = paid;
		if (distribId != null) o.distributionId = distribId;
		
		if (prevOrders.length > 0) {
			for (prevOrder in prevOrders) {
				if (!prevOrder.paid) {
					o.quantity += prevOrder.quantity;
					prevOrder.delete();
				}
			}
		}
		
		o.insert();
		
		//stocks
		if (o.product.stock != null) {
			var c = o.product.contract;
			if (c.hasStockManagement()) {
				if (o.product.stock == 0) {
					App.current.session.addMessage("Il n'y a plus de '" + o.product.name + "' en stock, nous l'avons donc retiré de votre commande", true);
					o.delete();
					return;
					
				}else if (o.product.stock - quantity < 0) {
					var canceled = quantity - o.product.stock;
					o.quantity -= canceled;
					o.update();
					
					App.current.session.addMessage("Nous avons réduit votre commande de '" + o.product.name + "' à "+o.quantity+" articles car il n'y a plus de stock disponible", true);
					o.product.lock();
					o.product.stock = 0;
					o.product.update();
					
				}else {
					o.product.lock();
					o.product.stock -= quantity;
					o.product.update();	
				}
				
			}	
		}
		
		
	}
	
	
	/**
	 * Edit an order (quantity)
	 */
	public static function edit(order:db.UserContract, newquantity:Float, ?paid:Bool) {
		
		
		
		
		order.lock();
		
		//paid
		if (paid != null) {
			order.paid = paid;
		}else {
			if (order.quantity < newquantity) order.paid = false;	
		}
		
		
		//stocks
		if (order.product.stock != null) {
			var c = order.product.contract;
			
			if (c.hasStockManagement()) {
				
				
				if (newquantity < order.quantity) {
					
					//on commande moins que prévu : incrément de stock						
					order.product.lock();
					order.product.stock +=  (order.quantity-newquantity);
					order.product.update();
					
				}else {
				
					//on commande plus que prévu : décrément de stock
					
					var addedquantity = newquantity - order.quantity;
					
					if (order.product.stock - addedquantity < 0) {
						//modification de commande
						newquantity = order.quantity + order.product.stock;
						
						App.current.session.addMessage("Nous avons réduit votre commande de '" + order.product.name + "' à "+newquantity+" articles car il n'y a plus de stock disponible", true);
						order.product.lock();
						order.product.stock = 0;
						order.product.update();
						
					}else {
						order.product.lock();
						order.product.stock -= addedquantity;
						order.product.update();	
					}
					
				}
				
				
				
				
			}	
		}
		
		
		if (newquantity == 0) {
			order.delete();
		}else {
			order.quantity = newquantity;
			order.update();	
		}
		
		
		
	}
}