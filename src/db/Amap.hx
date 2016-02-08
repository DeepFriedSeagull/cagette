package db;
import sys.db.Object;
import sys.db.Types;

enum AmapFlags {
	HasMembership; 	//gestion des adhésions
	ShopMode; 		//mode boutique
	IsAmap; 		//Amap / groupement d'achat
	ComputeMargin;	//compute margin instead of percentage
}

/**
 * AMAP
 */
class Amap extends Object
{
	public var id : SId;
	public var name : SString<32>;
	
	@formPopulate("getMembersFormElementData") @:relation(userId)
	public var contact : SNull<User>;
	
	public var txtIntro:SNull<SText>; 	//introduction de l'amap
	public var txtHome:SNull<SText>; 	//texte accueil adhérents
	public var txtDistrib:SNull<SText>; //sur liste d'emargement
	
	public var membershipRenewalDate : SNull<SDate>;
	@hideInForms  public var membershipPrice : SNull<STinyInt>;
	
	@hideInForms 
	public var vatRates : SData<Map<String,Float>>;
	
	public var flags:SFlags<AmapFlags>;
	
	@hideInForms @:relation(imageId)
	public var image : SNull<sugoi.db.File>;
	
	@hideInForms public var cdate : SDateTime;
	@hideInForms @:relation(placeId) public var mainPlace : SNull<db.Place>;
	
	public function new() 
	{
		super();
		flags = cast 0;
		vatRates = ["TVA Alimentaire 5,5%" => 5.5, "TVA 20%" => 20];
		cdate = Date.now();
		
	}
	
	/**
	 * find the most common delivery place
	 */
	public function getMainPlace() {
	
		if (mainPlace != null && Std.random(100) != 0) {
			return mainPlace;
		}else {
			this.lock();
			//var cids = Lambda.map(getActiveContracts(), function(x) return x.id);
			var places = getPlaces();
			if (places.length == 1) {				
				this.mainPlace = places.first();
				this.update();				
			}
			
			var pids = Lambda.map(places, function(x) return x.id);
			
			var res = sys.db.Manager.cnx.request("select placeId,count(placeId) as top from Distribution where placeId IN ("+pids.join(",")+") group by placeId order by top desc").results();
			
			var pid = Std.parseInt(res.first().placeId);
			
			
			if (pid != 0 && pid != null) {
				var p = db.Place.manager.get(pid, false);
				this.mainPlace = p;
				this.update();
				return p;
			}else {
				return null;	
			}
		}
	}
	
	
	public function hasMembership():Bool {
		return flags != null && flags.has(HasMembership);
	}
	
	public function hasShopMode() {
		return flags.has(ShopMode);
	}
	
	public function getCategoryGroups() {
		return db.CategoryGroup.get(this);
	}
	
	
	//public function canAddMember():Bool {
	//	return isAboOk(true);
	//}
	
	/**
	 * Renvoie la liste des contrats actifs
	 * @param	large=false
	 */
	public function getActiveContracts(?large=false) {
		return Contract.getActiveContracts(this, large, false);
	}
	
	public function getContracts() {
		return Contract.manager.search($amap == this, false);
	}
	
	/**
	 * récupere les produits des contracts actifs
	 */
	public function getProducts() {
		var contracts = db.Contract.getActiveContracts(App.current.user.amap,false,false);
		return Product.manager.search( $contractId in Lambda.map(contracts, function(c) return c.id),{orderBy:name}, false);
	}
	
	public function getPlaces() {
		return Place.manager.search($amap == this, false);
	}
	
	public function getVendors() {
		return Vendor.manager.search($amap == this, false);
	}
	
	public function getMembers() {
		return User.manager.unsafeObjects("Select u.* from User u,UserAmap ua where u.id=ua.userId and ua.amapId="+this.id+" order by u.lastName", false);
	}
	
	public function getMembersFormElementData():Array<{key:String,value:String}> {
		var m = getMembers();
		var out = [];
		var name = "";
		for (mm in m) {
			name = mm.getName();
			if (mm.lastName2 != null) name = name + " / " + mm.lastName2 +" " + mm.firstName2;
			
			out.push({key:Std.string(mm.id),value:name });
		}
		return out;
	}
	
	override public function toString() {
		if (name != '' && name != null) {
			return name;
		}else {
			return 'group#' + id;
		}
	}
	
	/**
	 * pour avoir le nom de la periode de cotisation pour une date donnée
	 */
	public function getPeriodName(?d:Date):String {
		if (d == null) d = Date.now();
		var year = getMembershipYear(d);
		return getPeriodNameFromYear(year);
	}
	
	/**
	 * Si la date de renouvellement est en janvier ou février, on note la cotisation avec l'année en cours,
	 * sinon c'est "à cheval" donc on note la cotis avec l'année la plus ancienne (ex:2014 pour une cotis 2014-2015)
	 */
	public function getMembershipYear(?d:Date):Int {
		if (d == null) d = Date.now();
		var year = d.getFullYear();
		var n = membershipRenewalDate;
		if (n == null) n = Date.now();
		var renewalDate = new Date(year, n.getMonth(), n.getDate(), 0, 0, 0);
		
		//if (membershipRenewalDate.getMonth() <= 1) {
			
			if (d.getTime() < renewalDate.getTime()) {
				return year-1;
			}else {
				return year;
			}
			
		//}else {
			//return year - 1;
		//}
	}
	
	/**
	 * à partir d'une année de cotis enregistrée, afficher le nom de la periode
	 * @param	y
	 */
	public function getPeriodNameFromYear(y:Int):String {
		if (membershipRenewalDate!=null && membershipRenewalDate.getMonth() <= 1) {
			return Std.string(y);
		}else {
			return Std.string(y) + "-" + Std.string(y+1);
		}
	}
	
	
}