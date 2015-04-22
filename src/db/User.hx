package db;
import sys.db.Object;
import sys.db.Types;
import db.UserAmap;
enum UserFlags {
	HasEmailNotif;
	//Pipo;
	//Lol;
}

enum RightSite {
	Admin;
}

@:index(email,unique)
class User extends Object{
	
	public var id : SId;
	public var lang : SString<2>;
	@:skip public var name(get, set) : String;
	public var pass : STinyText;
	public var rights : SFlags<RightSite>; //droits niveau site : moderateur, admin...
	
	public var firstName:SString<32>;
	public var lastName:SString<32>;
	public var email : SString<64>;
	public var phone:SNull<SString<19>>;
	
	public var firstName2:SNull<SString<32>>;
	public var lastName2:SNull<SString<32>>;
	public var email2 : SNull<STinyText>;
	public var phone2:SNull<SString<19>>;
	
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SNull<SString<32>>;
	public var city:SNull<SString<25>>;
	
	//@:relation(amapId) public var amap:SNull<db.Amap>;   public var amapId:SNull<SInt>;
	@:skip public var amap(get_amap, null) : Amap;
	
	public var cdate : SDate; 				//creation
	public var ldate : SNull<SDateTime>;	//derniere connexion
	
	public var flags : SFlags<UserFlags>;
	
	public function new() {
		super();
		rights = sys.db.Types.SFlags.ofInt(0);
		flags = sys.db.Types.SFlags.ofInt(0);
		pass = haxe.crypto.Md5.encode( App.App.config.get('key') + ""); //pass = ""
		ldate = cdate = Date.now();
	}
	
	public override function toString() {
		return getName()+" ["+id+"]";
	}

	public function isAdmin() {
		return rights.has(Admin) || id==1;
	}
	
	public function isAmapManager() {
		//if (isAdmin()) return true;
		//if (getAmap().contact == null) throw "Cette AMAP n'a pas de responsable général.";
		return getUserAmap(getAmap()).hasRight(Right.AmapAdmin);
	}
	
	function getUserAmap(amap:db.Amap):db.UserAmap {
		return db.UserAmap.get(this, amap);
	}
	
	/**
	 * Est ce que ce membre a la gestion de ce contrat
	 * si null, est ce qu'il a la gestion d'un contrat
	 * @param	contract
	 */
	public function isContractManager(?contract:db.Contract ) {
		if (isAdmin()) return true;
		var ua = getUserAmap(getAmap());
		if (ua.rights == null) return false;
		if (ua.hasRight(Right.ContractAdmin())) return true;
		
		if (contract != null) {
			//return contract.contact.id==this.id && App.current.user.amap.id==contract.amap.id;
			return ua.hasRight(Right.ContractAdmin(contract.id));
		}else {
			
			for (r in ua.rights) {
				switch(r) {
					case Right.ContractAdmin(cid):
						return true;
					default:
				}
			}
			return false;			
		}
		
	}
	
	public function canAccessMessages():Bool {
		var ua = getUserAmap(getAmap());
		if (ua.hasRight(Right.Messages)) return true;
		return false;
	}
	
	public function canAccessMembership():Bool {
		var ua = getUserAmap(getAmap());
		if (ua.hasRight(Right.Membership)) return true;
		return false;
	}
	
	public function canManageContract(c:db.Contract):Bool {
		var ua = getUserAmap(getAmap());
		if (ua.hasRight(Right.ContractAdmin())) return true;
		if (ua.hasRight(Right.ContractAdmin(c.id))) return true;		
		return false;
	}
	
	/**
	 * nouvelle gestion des droits
	 */
	//public function hasRight(right:db.Rights.RightType, ?subject:Int):Bool {
		//
		////ces deux statuts donnent accès à tout
		//if (isAdmin() || isAmapManager()) return true;
		//
		//var rights = db.Rights.manager.search($user == App.current.user && $amap == App.current.user.amap, false);
		//if (rights.length == 0) return false;
		//var hasright = Lambda.filter(rights, function(r) return r.rightType == right).length > 0;
		//
		//switch(right) {
			////case db.Rights.RightType.ContractAdmin :
			//
			//default:
				//return hasright;
			//
		//}
		//
	//}
	
	public function getContractManager(?lock=false) {
		return Contract.manager.search($amap == amap && $contact == this, false);
	}
	
	public function getName() {
		return get_name();
	}
	
	public function get_name() {
		return lastName + " " + firstName;
	}
	
	public function getCoupleName() {
		var n = lastName + " " + firstName;
		if (lastName2 != null) {
			n = n + " / " + lastName2 + " " + firstName2;
		}
		return n;
	}
	
	public function set_name(name:String) {
		var name = name.split(' ');
		firstName = name[0];
		lastName = name[1];
		return firstName+" "+lastName;
	}
	
	/*public function sendWelcomeMail() {
		var mail = new MandrillMail();
		mail.setRecipient(email,getName(),id);
		mail.setSender(App.App.config.get("webmaster_email"),App.App.config.get("webmaster_name"));
		mail.setHtmlBody("mail/welcome.mtt", {amap:amap} );
		mail.send();
		
	}*/
	
	public function setPass(p:String) {
		this.pass = haxe.crypto.Md5.encode( App.App.config.get('key') + StringTools.trim(p));
		return this.pass;
	}
	
	/**
	 * Renvoie les commandes actuelles du user
	 * @param	lock=false
	 * @return
	 */
	public function getOrders(?lock = false):List<UserContract> {
		
		var out =  UserContract.manager.search(($userId == id || $userId2 == id) && $amap==App.current.user.amap, lock);
		//TODO : faire ce tri directement en SQL
		for ( uc in Lambda.array(out).copy() ) {
			if (uc.product.contract.endDate.getTime() < Date.now().getTime()) {
				out.remove(uc);
			}
		}
		return out;
		
	}
	
	public function get_amap():Amap {
		return getAmap();
	}
	
	/**
	 * renvoie l'amap selectionnée par le user en cours
	 */
	public function getAmap() {
		
		//return Amap.manager.get(1);
		
		if (App.current.user != null && id != App.current.user.id) throw "cette fonction n'est valable que pour le joueur en cours";
		if (App.current.session == null) return null;
		var a = App.current.session.data.amapId;
		if (a == null) {
			//throw handler.Handler.HandlerAction.ActGoto("/user/choose");
			return null;
		}else {			
			return Amap.manager.get(a,false);
		}
	}
	
	/**
	 * renvoie toutes les amaps aupres desquelles le user appartient
	 */
	public function getAmaps() {
		return Lambda.map(UserAmap.manager.search($user == this, false), function(o) return o.amap);
	}
	
	public function isMemberOf(amap:Amap) {
		return UserAmap.manager.select($user == this && $amapId == amap.id, false) != null;
	}
	
	
	
	public function getContracts(?lock=false):Array<Contract> {
		var out = [];
		var ucs = getOrders(lock);
		for (uc in ucs) {
			if (!Lambda.has(out, uc.product.contract)) {
				out.push(uc.product.contract);
			}	
		}
		return out;
		
	}
	
	/**
	 * recherche des users similaires 
	 * @param	amapId
	 * @param	firstName
	 * @param	lastName
	 * @param	email
	 * @return
	 */
	public static function getSimilar(firstName:String, lastName:String, email:String,?firstName2:String, ?lastName2:String, ?email2:String):List<db.User> {
		var out = new Array();
		out = Lambda.array(User.manager.search($firstName.like(firstName) && $lastName.like(lastName), false));
		out = out.concat(Lambda.array(User.manager.search($email.like(email), false)));
		out = out.concat(Lambda.array(User.manager.search($firstName2.like(firstName) && $lastName2.like(lastName), false)));
		out = out.concat(Lambda.array(User.manager.search($email2.like(email), false)));
		
		//recherche pour le deuxieme user
		if (lastName2 != "" && lastName2 != null && firstName2 != "" && firstName2 != null) {
			out = out.concat(Lambda.array(User.manager.search($firstName.like(firstName2) && $lastName.like(lastName2), false)));
			out = out.concat(Lambda.array(User.manager.search($email.like(email2), false)));
			out = out.concat(Lambda.array(User.manager.search($firstName2.like(firstName2) && $lastName2.like(lastName2), false)));
			out = out.concat(Lambda.array(User.manager.search($email2.like(email2), false)));	
		}
		
		
		//dedoublage
		var x = new Map<Int,db.User>();
		for ( oo in out) {
			x.set(oo.id, oo);
		}
		return Lambda.list(x);
	}
	
	
	public static function getUsers_NoContracts(?index:Int,?limit:Int):List<db.User> {
		var productsIds = App.current.user.getAmap().getProducts().map(function(x) return x.id);
		var uc = UserContract.manager.search($productId in productsIds, false);
		var uc2 = uc.map(function(x) return x.userId); //liste des userId avec un contrat dans cette amap
		//les gens qui sont dans cette amap et qui n'ont pas de contrat de cette amap
		var ua = db.UserAmap.manager.unsafeObjects("select * from UserAmap where amapId=" + App.current.user.getAmap().id +" and userId NOT IN(" + uc2.join(",") + ")", false);						
		return Lambda.map(ua, function(x) return x.user);	
	}
	
	public static function getUsers_NoMembership(?index:Int,?limit:Int):List<db.User> {
		var ua = new List();
		if (index == null && limit == null) {
			ua = db.UserAmap.manager.search($amap == App.current.user.amap, false);	
		}else {
			ua = db.UserAmap.manager.search($amap == App.current.user.amap,{limit:[index,limit]}, false);
		}
		
		for (u in Lambda.array(ua)) {
			if (u.hasValidMembership()) ua.remove(u);
		}
		
		return Lambda.map(ua, function(x) return x.user);	
	}
	
	
	
}
