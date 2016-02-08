package db;
import sys.db.Object;
import sys.db.Types;
import db.UserAmap;
enum UserFlags {
	HasEmailNotif4h;
	HasEmailNotif24h;
	//Lol;
}

enum RightSite {
	Admin;
}

@:index(email,unique)
class User extends Object {

	public static var EMPTY_PASS = "859738d2fed6a98902defb00263f0d35";
	
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
	public var email2 : SNull<SString<64>>;
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
	
	/**
	 * is this user the manager of the current group
	 */
	public function isAmapManager() {
		//if (getAmap().contact == null) throw "Cette AMAP n'a pas de responsable général.";
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		return ua.hasRight(Right.AmapAdmin);
	}
	
	function getUserAmap(amap:db.Amap):db.UserAmap {
		return db.UserAmap.get(this, amap);
	}
	
	/**
	 * Est ce que ce membre a la gestion de ce contrat
	 * si null, est ce qu'il a la gestion d'un des contrat, n'importe lequel (utilse pour afficher 'gestion contrat' dans la nav )
	 * @param	contract
	 */
	public function isContractManager(?contract:db.Contract ) {
		if (isAdmin()) return true;
		if (contract != null) {			
			return canManageContract(contract);
		}else {
			var ua = getUserAmap(getAmap());
			if (ua == null) return false;
			if (ua.rights == null) return false;
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
		if (ua == null) return false;
		if (ua.hasRight(Right.Messages)) return true;
		return false;
	}
	
	public function canAccessMembership():Bool {
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
		if (ua.hasRight(Right.Membership)) return true;
		return false;
	}
	
	public function canManageContract(c:db.Contract):Bool {
		var ua = getUserAmap(getAmap());
		if (ua == null) return false;
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
	
	public function setPass(p:String) {
		this.pass = haxe.crypto.Md5.encode( App.config.get('key') + StringTools.trim(p));
		return this.pass;
	}
	
	/**
	 * Renvoie les commandes actuelles du user
	 * @param	_amap		force une amap
	 * @param	lock=false
	 */
	public function getOrders(?_amap:db.Amap,?lock = false):List<UserContract> {
		var a = _amap == null ? getAmap() : _amap;
		var c = a.getActiveContracts(true);
		var cids = Lambda.map(c,function(m) return m.id);
		var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		var out =  UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, lock);		
		return out;
		
	}
	
	/**
	 * renvoie les commandes à partir d'une liste de contrats
	 */
	public function getOrdersFromContracts(c:List<db.Contract>):List<db.UserContract> {
		var cids = Lambda.map(c,function(m) return m.id);
		var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		return UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, false);		
	}
	
	/**
	 * renvoie les commandes de contrat variables à partir d'une distribution
	 */
	public function getOrdersFromDistrib(d:db.Distribution):List<db.UserContract> {
		var pids = Lambda.map(db.Product.manager.search($contractId == d.contract.id, false), function(x) return x.id);		
		return UserContract.manager.search(($userId == id || $userId2 == id) && $distributionId==d.id && $productId in pids , false);	
	}
	
	public function get_amap():Amap {
		return getAmap();
	}
	
	/**
	 * renvoie l'amap selectionnée par le user en cours
	 */
	public function getAmap() {
		
		if (App.current.user != null && id != App.current.user.id) throw "cette fonction n'est valable que pour l'utilisateur en cours";
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
	public function getAmaps():List<db.Amap> {
		return Lambda.map(UserAmap.manager.search($user == this, false), function(o) return o.amap);
	}
	
	public function isMemberOf(amap:Amap) {
		return UserAmap.manager.select($user == this && $amapId == amap.id, false) != null;
	}
	
	
	/**
	 * Renvoie la liste des contrats dans lequel l'adherent a des commandes
	 * @param	lock=false
	 * @return
	 */
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
	 * Merge fields of 2 users, then delete the second (u2)
	 * Be carefull : check before calling this function that u2 can be safely deleted !
	 */
	public function merge(u2:db.User) {
		
		this.lock();
		u2.lock();
		
		var m = function(a, b) {
			return a == null || a=="" ? b : a;
		}
		
		this.address1 = m(this.address1, u2.address1);
		this.address2 = m(this.address2, u2.address2);
		this.zipCode = m(this.zipCode, u2.zipCode);
		this.city = m(this.city, u2.city);
		
		//find how to merge the 2 names in each account
		if (this.email == u2.email) {
			
			this.firstName = m(this.firstName, u2.firstName);
			this.lastName = m(this.lastName, u2.lastName);
			this.phone = m(this.phone, u2.phone);
			
		} else if (this.email == u2.email2) {
			
			this.firstName = m(this.firstName, u2.firstName2);
			this.lastName = m(this.lastName, u2.lastName2);
			this.phone = m(this.phone, u2.phone2);
		} 
		
		if (this.email2 == u2.email) {
			
			this.firstName2 = m(this.firstName2, u2.firstName);
			this.lastName2 = m(this.lastName2, u2.lastName);
			this.phone2 = m(this.phone2, u2.phone);
			
		} else if (this.email2 == u2.email2) {
			
			this.firstName2 = m(this.firstName2, u2.firstName2);
			this.lastName2 = m(this.lastName2, u2.lastName2);
			this.phone2 = m(this.phone2, u2.phone2);
			
		}
		
		u2.delete();
		this.update();
		
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
			out = out.concat(Lambda.array(User.manager.search($firstName2.like(firstName2) && $lastName2.like(lastName2), false)));			
		}
		if (email2 != null && email2 != "") {
			out = out.concat(Lambda.array(User.manager.search($email.like(email2), false)));
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
	
	public static function getUsers_NewUsers(?index:Int, ?limit:Int):List<db.User> {
		//var uas = new List();
		//if (index == null && limit == null) {
			//uas = db.UserAmap.manager.search($amap == App.current.user.amap, false);	
		//}else {
			//uas = db.UserAmap.manager.search($amap == App.current.user.amap,{limit:[index,limit]}, false);
		//}
		//var out = new List();
		//for ( ua in uas) {
			//if (ua.user.pass == db.User.EMPTY_PASS) out.add(ua.user);
		//}
		//
		//return out;
		
		var uas = db.UserAmap.manager.search($amap == App.current.user.amap, false);
		var ids = Lambda.map(uas, function(x) return x.userId);
		if (index == null && limit == null) {
			return  db.User.manager.search($pass == db.User.EMPTY_PASS && ($id in ids), {orderBy:lastName} ,false);
		}else {
			return  db.User.manager.search($pass == db.User.EMPTY_PASS && ($id in ids), {limit:[index, limit] ,orderBy:lastName} , false);			
		}
		
	}
	
	public function sendInvitation() {
		
		if (pass!=null && pass != "" && pass != EMPTY_PASS) throw "cet utilisateur ne peut pas recevoir d'invitation";
		
		
		var group : db.Amap = null;
		
		if (App.current.user == null) {			
			group = this.getAmaps().first();	
		}else {
			//prend l'amap du user connecté qui a lancé l'invite.
			group = App.current.user.amap;	
		}
		
		if (group == null) throw "cet utilisateur n'est affilié à aucun groupe";
		
		//store token
		var k = sugoi.db.Session.generateId();
		sugoi.db.Cache.set("validation" + k, this.id, 60 * 60 * 24 * 7); //expire dans une semaine
		
		
		var e = new ufront.mail.Email();		
		e.setSubject("Invitation "+group.name);
		e.to(new ufront.mail.EmailAddress(this.email,this.getName()));
		e.from(new ufront.mail.EmailAddress(App.config.get("default_email"),"Cagette.net"));			
		
		var html = App.current.processTemplate("mail/invitation.mtt", { email:email, email2:email2, group:group.name,name:firstName,k:k } );		
		e.setHtml(html);
		
		App.getMailer().send(e);
		
		
	}
	
	/**
	 * cleaning before saving
	 */
	override public function insert() {
		clean();
		super.insert();
	}
	
	override public function update() {
		clean();
		super.update();
	}
	
	function clean() {
		
		//emails
		this.email = this.email.toLowerCase();
		if (this.email2 != null) this.email2 = this.email2.toLowerCase();
		
		//lastname
		this.lastName = this.lastName.toUpperCase();
		if (this.lastName2 != null) this.lastName2 = this.lastName2.toUpperCase();
	}
	
	
	
}
