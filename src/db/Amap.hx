package db;
import sys.db.Object;
import sys.db.Types;

enum AmapFlags {
	HasMembership; //gestion des adhésions
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
	
	public var txtIntro:SText; 	//introduction de l'amap
	public var txtHome:SNull<SText>; 	//texte accueil adhérents
	public var txtDistrib:SText; //sur liste d'emargement
	
	public var aboEnd : SNull<SDate>; //dépassé = retombe en mode gratuit
	public var aboType : STinyInt; //id de type d'abonnement
	public var emailStock : SUInt;
	public var smsStock : SUInt;
	
	public var membershipRenewalDate : SNull<SDate>;
	public var membershipPrice : SNull<STinyInt>;
	
	public var flags:SFlags<AmapFlags>;
	
	public function new() 
	{
		super();
		aboType = 0;
		emailStock = 200;
	}
	
	public function isAboOk(?plusOne=false):Bool {
	
		var members = UserAmap.manager.count($amap == App.current.user.amap);
		if (plusOne) members++;
		
		//abo null ou expiré ?
		if (aboEnd == null || Date.now().getTime() > (aboEnd.getTime() + (1000*60*60*24))) {
			
			//mode free ?
			if (members <= Const.ABO_MAX_MEMBERS[0]) return true;
			
			return false;
		}else {
			//abo valable
			return (members <= Const.ABO_MAX_MEMBERS[aboType]); 
			
		}
		
		return false;
	}
	
	public function hasMembership():Bool {
		return flags != null && flags.has(HasMembership);
	}
	
	public function canAddMember():Bool {
		return isAboOk(true);
	}
	
	/**
	 * Renvoie la liste des contrats actifs
	 * @param	large=false
	 */
	public function getActiveContracts(?large=false) {
		return Contract.getActiveContracts(this, large, false);
	}
	
	public function getContracts() {
		return Contract.manager.select($amap == this, false);
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
		//var uids = db.UserAmap.manager.search($amap == this, false);
		//return Lambda.map(uids, function(ua) return ua.user);
		return User.manager.unsafeObjects("Select u.* from User u,UserAmap ua where u.id=ua.userId and ua.amapId="+this.id+" order by u.lastName", false);
		
		//return User.manager.search($amapId == id,{orderBy:lastName}, false);
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
		return name;
	}
	
	
	
}