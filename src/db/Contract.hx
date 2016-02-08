package db;
import sys.db.Object;
import sys.db.Types;

enum ContractFlags {
	UsersCanOrder;  		//adhérents peuvent saisir eux meme la commande en ligne
	StockManagement; 		//gestion des commandes
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
	
	public var description:SNull<SText>;
	
	@:relation(amapId) public var amap:Amap;
	public var distributorNum:STinyInt;
	public var flags : SFlags<ContractFlags>;
	
	public var percentageValue : SNull<SInt>; 		//% commission sur les ventes
	public var percentageName : SNull<SString<64>>;	//nom de la commission, ex "participation aux frais"
	
	public var type : SInt;
	@:skip public static var TYPE_CONSTORDERS = 0; 	//à commande fixes
	@:skip public static var TYPE_VARORDER = 1;		//à commandes variables
	
	@:skip var cache_hasActiveDistribs : Bool;
	
	public function new() 
	{
		super();
	}
	
	/**
	 * The products can be ordered currently ?
	 */
	public function isUserOrderAvailable():Bool {
		
		if (type == TYPE_CONSTORDERS ) {
			
			// constant orders
			return isVisibleInShop();
		}else {
		
			if ( cache_hasActiveDistribs != null ) return cache_hasActiveDistribs;
			
			//for varying orders, we need to know if there are some available deliveries
			var n = Date.now();
			
			var d = db.Distribution.manager.count( $orderStartDate <= n && $orderEndDate >= n && $contractId==this.id);
			//tmp : add the "old" deliveries which have a null orderStartDate
			d += db.Distribution.manager.count( $orderStartDate == null && $date > n  && $contractId == this.id );
			
			cache_hasActiveDistribs = d > 0;
			return cache_hasActiveDistribs && isVisibleInShop();
		}
		
	}
	
	/**
	 * The products can be displayed in a shop ?
	 */
	public function isVisibleInShop():Bool {
		
		//yes if the contract is active and the 'UsersCanOrder' flag is checked
		var n = Date.now().getTime();
		return flags.has(UsersCanOrder) && n < this.endDate.getTime() && n > this.startDate.getTime();
	}
	
	public function hasPercentageOnOrders():Bool {
		return flags.has(PercentageOnOrders) && percentageValue!=null && percentageValue!=0;
	}
	
	public function hasStockManagement():Bool {
		return flags.has(StockManagement);
	}
	
	/**
	 * computes a 'percentage' fee or a 'margin' fee 
	 * depending on the group settings
	 * 
	 * @param	basePrice
	 */
	public function computeFees(basePrice:Float) {
		if (!hasPercentageOnOrders()) return 0.0;
		
		if (amap.flags.has(ComputeMargin)) {
			//commercial margin
			return (basePrice / ((100 - percentageValue) / 100)) - basePrice;
			
		}else {
			//add a percentage
			return percentageValue / 100 * basePrice;
		}
	}
	
	/**
	 * 
	 * @param	amap
	 * @param	large = false	Si true, montre les contrats terminés depuis moins d'un mois
	 * @param	lock = false
	 */
	public static function getActiveContracts(amap:Amap,?large = false, ?lock = false) {
		var now = Date.now();
		var end = Date.now();
	
		if (large) {
			end = DateTools.delta(end , -1000.0 * 60 * 60 * 24 * 30);
			return db.Contract.manager.search($amap == amap && $endDate > end,{orderBy:-startDate}, lock);	
		}else {
			return db.Contract.manager.search($amap == amap && $endDate > now && $startDate < now,{orderBy:-startDate}, lock);	
		}
		
		
	}
	
	/**
	 * get products in this contract
	 * @param	onlyActive = true
	 * @return
	 */
	public function getProducts(?onlyActive = true):List<Product> {
		if (onlyActive) {
			return Product.manager.search($contract==this && $active==true,false);	
		}else {
			return Product.manager.search($contract==this,false);	
		}
		
	}
	
		
	
	public function getUsers():Array<db.User> {
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
	
	public function getOrders(?d:db.Distribution):Array<db.UserContract> {
		if (type == TYPE_VARORDER && d == null) throw "Il faut spécifier une livraison pour ce type de contrat";
		
		var pids = getProducts().map(function(x) return x.id);
		var ucs = new List<db.UserContract>();
		if (d != null) {
			ucs = UserContract.manager.search( ($productId in pids) && $distribution==d,{orderBy:userId}, false);	
		}else {
			ucs = UserContract.manager.search($productId in pids,{orderBy:userId}, false);	
		}		
		return Lambda.array(ucs);
	}
	
	public function getDistribs(excludeOld = true,?limit=999):List<Distribution> {
		if (excludeOld) {
			//still include deliveries which just expired in last 24h
			return Distribution.manager.search($end > DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24) && $contract == this, { orderBy:date,limit:limit } );
		}else{
			return Distribution.manager.search( $contract == this, { orderBy:date,limit:limit } );
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