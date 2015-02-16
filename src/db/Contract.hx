package db;
import sys.db.Object;
import sys.db.Types;

enum ContractFlags {
	UsersCanOrder;  		//adhérents peuvent saisir eux meme la commande
	OrdersManuallyEnabled; 	//fermeture/ouverture manuelle des commandes
	PercentageOnOrders;		//calcul d'une commission supplémentaire 
	
	//LogisticMgmt;		//gestion logistique
	//SubGroups;		//sous groupes pour commandes groupées
	//InviteFriends;	//peut inviter des amis à participer à la commande
	
}

/**
 * Contract
 * 
 * un contrat réunissant pluseiurs produits d'un meme fournisseur
 * qui sont livrés au meme endroit et meme moment;
 * 
 */
class Contract extends Object
{

	public var id : SId;
	public var name : SString<64>;
	
	//responsable
	@formPopulate("populate") @:relation(userId) public var contact : SNull<User>;
	@formPopulate("populateVendor") @:relation(vendorId) public var vendor : Vendor;
	
	public var startDate:SDate;
	public var endDate :SDate;
	@:relation(amapId) public var amap:Amap;
	public var distributorNum:STinyInt;
	public var flags : SFlags<ContractFlags>;
	
	public var percentageValue : SNull<SInt>; 		//% commission sur les ventes
	public var percentageName : SNull<SString<64>>;	//nom de la commission, ex "participation aux frais"
	
	public var type : SInt;
	@:skip public static var TYPE_CONSTORDERS = 0; 	//à commande fixes
	@:skip public static var TYPE_VARORDER = 1;		//à commandes variables
	
	public function new() 
	{
		super();
	}
	
	public function isUserOrderAvailable():Bool {
		return flags.has(OrdersManuallyEnabled) && flags.has(UsersCanOrder);
	}
	public function hasPercentageOnOrders():Bool {
		return flags.has(PercentageOnOrders);
	}
	
	
	public static function getActiveContracts(amap:Amap,?large = false, ?lock = false) {
		
		var start = Date.now();
		var end = Date.now();
		
		if (large) {
			start = DateTools.delta(start, 1000.0 * 60 * 60 * 24 * 30);
			end = DateTools.delta(end , -1000.0 * 60 * 60 * 24 * 30);
		}
		
		return db.Contract.manager.search($amap == amap && $endDate > end && $startDate < start,{orderBy:-startDate}, lock);
	}
	
	public function getProducts():List<Product> {
		return Product.manager.search($contract==this,false);
	}
	
	
	
	public function getUsers() {
		var pids = getProducts().map(function(x) return x.id);
		var ucs = UserContract.manager.search($productId in pids, false);
		var ucs = Lambda.map(ucs, function(a) return a.user);
		
		//comme un user peut avoir plusieurs produits au sein d'un contrat, il faut dédupliquer cette liste
		var out = new Map<Int,db.User>();
		for (u in ucs) {
			out.set(u.id, u);
		}
		
		return Lambda.array(out);
	}
	
	public function getDistribs(excludeOld = true):List<Distribution> {
		if (excludeOld) {
			return Distribution.manager.search($end > DateTools.delta(Date.now(), -1000 * 60 * 60 * 24) && $contract == this, { orderBy:date } );
		}else{
			return Distribution.manager.search( $contract == this, { orderBy:date } );
		}
	}
	
	override function toString() {
		return name+" du "+this.startDate.toString().substr(0,10)+" au "+this.endDate.toString().substr(0,10);
	}
	
	public function populate() {
		return App.current.user.amap.getMembersFormElementData();
	}
	
	public function populateVendor():Array<{key:String,value:String}> {
		var vendors = Vendor.manager.search($amap == App.current.user.amap, false);
		var out = [];
		for (v in vendors) {
			
			out.push({key:Std.string(v.id),value:v.name });
		}
		return out;
	}
	
	
}