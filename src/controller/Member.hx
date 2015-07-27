package controller;
import db.UserContract;
import haxe.Utf8;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import sugoi.form.validators.EmailValidator;
import neko.Web;
import sugoi.tools.Utils;


class Member extends Controller
{

	public function new()
	{
		super();
		if (!app.user.canAccessMembership()) throw Redirect("/");
		
		var e = new event.Event();
		e.id = "displayMember";
		App.current.eventDispatcher.dispatch(e);
	}
	
	@logged
	@tpl('member/default.mtt')
	function doDefault(?args:{?search:String,?select:String}) {
		var browse:Int->Int->List<Dynamic>;
		var uids = db.UserAmap.manager.search($amap == app.user.getAmap(), false);
		var uids = Lambda.map(uids, function(ua) return ua.userId);
		if (args != null && args.search != null) {
			//search
			browse = function(index:Int, limit:Int) {
				var search = StringTools.trim(args.search);
				return db.User.manager.search( ($lastName.like(search)||$lastName2.like(search)) && $id in uids , { orderBy:-id }, false);
			}
			view.search = args.search;
		}else if(args!=null && args.select!=null){
			
			switch(args.select) {
				case "nocontract":
					if (app.params.exists("csv")) {
						setCsvData(Lambda.array(db.User.getUsers_NoContracts()), ["firstName", "lastName", "email"], "Sans-contrats");
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NoContracts(index, limit); }	
					}
					
				case "nomembership" :
					if (app.params.exists("csv")) {
						setCsvData(Lambda.array(db.User.getUsers_NoMembership()), ["firstName", "lastName", "email"], "Adhesions-a-renouveller");
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NoMembership(index, limit); }
					}
				default:
					throw "selection inconnue";
			}
			view.select = args.select;
			
		}else {
			if (app.params.exists("csv")) {
				setCsvData(Lambda.array(db.User.manager.search( $id in uids, {orderBy:lastName}, false)), ["firstName", "lastName", "email"], "Adherents");
				return;
			}else {
				//default display
				browse = function(index:Int, limit:Int) {
					return db.User.manager.search( $id in uids, { limit:[index,limit], orderBy:lastName }, false);
				}
			}
			
			
		}
		
		var count = uids.length;
		var rb = new sugoi.tools.ResultsBrowser(count, 10, browse);
		view.members = rb;
	}
	
	
	@tpl("member/view.mtt")
	function doView(member:db.User) {
		
		view.member = member;
		var userAmap = db.UserAmap.get(member, app.user.amap);
		if (userAmap == null) throw Error("/member", "Cette personne ne fait pas partie de votre AMAP");
		
		view.userAmap = userAmap; 
		
		//orders
		var row = { constOrders:[], varOrders:new Map() };
			
		//commandes fixes
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == app.user.amap && $endDate > Date.now(), false);
		var orders = member.getOrdersFromContracts(contracts);
		row.constOrders = Lambda.array(orders);
		
		//commandes variables groupées par date de distrib
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == app.user.amap && $endDate > Date.now(), false);
		var distribs = new Map<String,Array<db.UserContract>>();
		for (c in contracts) {
			var ds = c.getDistribs();
			for (d in ds) {
				var k = d.date.toString().substr(0, 10);
				var orders = member.getOrdersFromDistrib(d);
				if (orders.length > 0) {
					if (!distribs.exists(k)) {
						distribs.set(k, Lambda.array(orders));
					}else {
						var z = distribs.get(k).concat(Lambda.array(orders));
						distribs.set(k, z);
					}	
				}
			}
		}
		row.varOrders = distribs;
		view.userContracts =row;
		
	}	
	
	@admin
	function doLoginas(user:db.User, amap:db.Amap) {
	
		if (!app.user.isAdmin()) return;
		
		App.current.session.setUser(user);
		App.current.session.data.amapId = amap.id;
		throw Redirect("/member/view/" + user.id );
	}
	
	@tpl('form.mtt')
	function doEdit(member:db.User) {
		
		if (member.isAdmin()) throw Error("/","Vous ne pouvez pas modifier le compte d'un administrateur");
		
		var form = sugoi.form.Form.fromSpod(member);
		
		//cleaning
		form.removeElement( form.getElement("pass") );
		form.removeElement( form.getElement("rights") );
		form.removeElement( form.getElement("lang") );		
		form.removeElement( form.getElement("ldate") );
		form.getElement("email").addValidator(new EmailValidator());
		form.getElement("email2").addValidator(new EmailValidator());
		
		if (form.checkToken()) {
			form.toSpod(member); //update model
			member.lastName = member.lastName.toUpperCase();
			if (member.lastName2 != null) member.lastName2 = member.lastName2.toUpperCase();
			member.update();
			throw Ok('/member/view/'+member.id,'Ce membre a été mis à jour');
		}
		
		view.form = form;
	}
	
	function doDelete(user:db.User) {
		
		if (!app.user.isContractManager()) throw "Vous ne pouvez pas faire ça.";
		if (user.id == app.user.id) throw "Vous ne pouvez pas vous effacer vous même.";
		
		var ua = db.UserAmap.get(user, app.user.amap, true);
		if (ua != null) {
			ua.delete();
			throw Ok("/member", user.getName() + " a bien été supprimé(e) de votre AMAP");
		}else {
			throw Error("/member", "Cette personne ne fait pas partie de \"" + app.user.amap.name+"\"");			
		}
		
		
	}
	
	@tpl('form.mtt')
	function doMerge(user:db.User) {
		
		if (!app.user.isContractManager()) throw "Vous ne pouvez pas faire ça.";
		
		view.title = "Fusionner un compte avec un autre";
		view.text = "Cette action permet de fusionner deux comptes ( quand vous avez des doublons dans la base de données par exemple).<br/>Les contrats du compte 2 seront rattachés au compte 1, puis le compte 2 sera effacé.<br/>Attention cette action n'est pas annulable.";
		
		var form = new Form("merge");
		
		var members = app.user.amap.getMembers();
		var members = Lambda.array(Lambda.map(members, function(x) return { key:Std.string(x.id), value:x.getName() } ));
		var mlist = new Selectbox("member1", "Compte 1", members, Std.string(user.id));
		form.addElement( mlist );
		var mlist = new Selectbox("member2", "Compte 2", members);
		form.addElement( mlist );
		
		if (form.checkToken()) {
		
			var m1 = Std.parseInt(form.getElement("member1").value);
			var m2 = Std.parseInt(form.getElement("member2").value);
			var m1 = db.User.manager.get(m1,true);
			var m2 = db.User.manager.get(m2,true);
			
			//if (m1.amapId != m2.amapId) throw "ils ne sont pas de la même amap !";
			
			//on prend tout à m2 pour donner à m1			
			//change usercontracts
			var contracts = m2.getOrders(true);
			for (c in contracts) {
				if (c.user.id == m2.id) c.user = m1;
				if (c.user2!=null && c.user2.id == m2.id) c.user2 = m1;
				c.update();
			}
			
			//change contacts
			var contacts = m2.getContractManager(true);
			for (c in contacts) {
				c.contact = m1;
				c.update();
			}
			if (m2.amap.contact == m2) {
				m1.amap.lock();
				m1.amap.contact = m1;
				m1.amap.update();
			}
			
			m2.delete();
			
			throw Ok("/member/view/" + m1.id, "Les deux comptes ont été fusionnés");
			
			
		}
		
		view.form = form;
		
	}
	
	
	@tpl('member/import.mtt')
	function doImport(?args:{confirm:Bool}) {
			
		var step = 1;
		var request = Utils.getMultipart(1024 * 1024 * 4);
		
		//on recupere le contenu de l'upload
		if (request.get("file") != null) {
			
			var data = request.get("file").split("\n");
			var unregistred = [];
			//fix fields like this : "23 allée des Taupes; Camboulis"
			for (d in data) {				
				var x = d.split('"');
				for (i in 0...x.length) {
					if (i % 2 == 1) x[i] = StringTools.replace(x[i], ";", ",");
				}
				d = x.join("");
				
				unregistred.push(d.split(";"));
				
				for (u in unregistred) {
					for (i in 0...u.length) {
						u[i] = StringTools.replace(u[i], ",", ";");
					}
				}
			}
			
			//cleaning
			for ( user in unregistred.copy() ) {
				//vire lignes vides
				if (user == null || user.length <= 1) {
					unregistred.remove(user);
					continue;
				}
				
				
				for (i in 0...user.length) {
					//mets les champs "" en null
					if (user[i] == "") {
						user[i] = null;
						continue;
					}
					
					//clean espaces et autres caracteres inutiles
					user[i] = StringTools.trim(user[i]);
					user[i] = StringTools.replace(user[i], "\n", "");
					user[i] = StringTools.replace(user[i], "\t", "");
					user[i] = StringTools.replace(user[i], "\r", "");
				}
				
				//check nom+prenom
				if (user[0] == null || user[1] == null) throw "Vous devez remplir le nom et prénom de la personne. <br/>Cette ligne est incomplète : " + user;
				if (user[2] == null) throw "Chaque personne doit avoir un email, sinon elle ne pourra pas se connecter. "+user[0]+" "+user[1]+" n'en a pas.";
				//uppercase du nom
				if(user[1]!=null) user[1] = user[1].toUpperCase();
				if (user[5] != null) user[5] = user[5].toUpperCase();
				
				App.log(user);
			}
			
			unregistred.shift(); //vire les headers du csv
			
			//utf-8 check
			for ( row in unregistred.copy()) {
				
				
				for ( i in 0...row.length) {
					var t = row[i];
					if (t != "" && t != null) {
						try{
							if (!Utf8.validate(t)) {
								t = Utf8.encode(t);	
							}
						}catch (e:Dynamic) {}
						row[i] = t;
					}
				}
			}
			
			//put already registered people in another list
			var registred = [];
			for (r in unregistred.copy()) {
				var firstName = r[0];
				var lastName = r[1];
				var firstName2 = r[4];
				var lastName2 = r[5];
					
				var us = db.User.manager.search(
					/*app.user.amapId == $amapId &&*/ (
					
						($firstName.like(firstName) && $lastName.like(lastName)) || 
						($firstName2!=null && $firstName2.like(firstName) && $lastName2.like(lastName)) ||
						
						($firstName.like(firstName2) && $lastName.like(lastName2)) || 
						($firstName2!=null && $firstName2.like(firstName2) && $lastName2.like(lastName2)) ||
						
						($email.like(r[2])) ||
						($email2!=null && $email2.like(r[2])) ||
						($email.like(r[6])) ||
						($email2!=null && $email2.like(r[6]))
					)
					
				,false);
				if (us.length > 0) {
					//trace(r[0]+" "+r[1]+" existe deja : "+us);
					unregistred.remove(r);
					registred.push(r);
				}
			}
			
			
			app.session.data.csvImportedData = unregistred;
			//trace("registred "+registred);
			view.data = unregistred;
			view.data2 = registred;
			step = 2;
		}
		
		if (args != null && args.confirm) {
			var i : Iterable<Dynamic> = cast app.session.data.csvImportedData;
			for (u in i) {
				if (u[0] == null || u[0] == "") continue;
								
				var user = new db.User();
				user.firstName = u[0];
				user.lastName = u[1];
				user.email = u[2];
				if (user.email != null && !EmailValidator.check(user.email)) {
					throw "Le mail '" + user.email + "' est invalide, merci de modifier votre fichier";
				}
				user.phone = u[3];
				
				user.firstName2 = u[4];
				user.lastName2 = u[5];
				user.email2 = u[6];
				if (user.email2 != null && !EmailValidator.check(user.email2)) {
					App.log(u);
					throw "Le mail du conjoint de "+user.firstName+" "+user.lastName+" '" + user.email2 + "' est invalide, merci de modifier votre fichier";
				}
				user.phone2 = u[7];
				
				user.address1 = u[8];
				user.address2 = u[9];
				user.zipCode = u[10];
				user.city = u[11];
				
				user.insert();
				
				var ua = new db.UserAmap();
				ua.user = user;
				ua.amap = app.user.amap;
				ua.insert();
			}
			
			view.numImported = app.session.data.csvImportedData.length;
			app.session.data.csvImportedData = null;
			
			step = 3;
		}
		
		if (step == 1) {
			//reset import when back to import page
			app.session.data.csvImportedData =	null;
		}
		
		view.step = step;
	}
	
	@tpl("user/insert.mtt")
	public function doInsert() {
		
		if (!app.user.isContractManager()) return;
		
		var e = new event.Event();
		e.id = "wantToAddMember";
		App.current.eventDispatcher.dispatch(e);
		
		var m = new db.User();
		var form = sugoi.form.Form.fromSpod(m);
		form.removeElement(form.getElement("lang"));
		form.removeElement(form.getElement("rights"));
		form.removeElement(form.getElement("pass"));	
		form.removeElement(form.getElement("ldate") );
		form.addElement(new sugoi.form.elements.Checkbox("warnAmapManager", "Envoyer un mail au responsable de l'AMAP", true));
		form.getElement("email").addValidator(new EmailValidator());
		form.getElement("email2").addValidator(new EmailValidator());
		
		if (form.isValid()) {
			
			//check doublon de User et de UserAmap
			var userSims = db.User.getSimilar(form.getValueOf("firstName"), form.getValueOf("lastName"), form.getValueOf("email"),form.getValueOf("firstName2"), form.getValueOf("lastName2"), form.getValueOf("email2"));
			view.userSims = userSims;
			var userAmaps = db.UserAmap.manager.search($amap == app.user.amap && $userId in Lambda.map(userSims, function(u) return u.id), false);
			view.userAmaps = userAmaps;
			
			if (userAmaps.length > 0) {
				//user deja enregistré dans cette amap
				throw Error('/member/view/' + userAmaps.first().userId, 'Cette personne est déjà inscrite dans cette AMAP');
				
			}else if (userSims.length > 0) {
				//des users existent avec ce nom , 
				if (userSims.length == 1) {
					// si yen a qu'un on l'inserte
					var ua = new db.UserAmap();
					ua.user = userSims.first();
					ua.amap = app.user.amap;
					ua.insert();	
					throw Ok('/member/','Cette personne était déjà inscrite sur Cagette.net, nous l\'avons inscrite à votre AMAP.');
				}else {
					//demander validation avant d'inserer le userAmap
					
					//TODO
					
					throw Error('/member',"Impossible d'ajouter cette personne car plusieurs personnes dans la base de données ont le même nom et prénom, contactez l'administrateur du site."+userSims);
					
				}
				return;
			}else {
				//insert user
				var u = new db.User();
				form.toSpod(u); 
				u.lang = "fr";
				u.lastName = u.lastName.toUpperCase();
				if (u.lastName2 != null) u.lastName2 = u.lastName2.toUpperCase();
				u.insert();
				
				//insert userAmap
				var ua = new db.UserAmap();
				ua.user = u;
				ua.amap = app.user.getAmap();
				ua.insert();	
				
				if (form.getValueOf("warnAmapManager") == "1") {
					var m = new sugoi.mail.MandrillApiMail();
					m.setSubject("Nouvel inscrit à l'AMAP : " + u.getCoupleName());
					m.setSender(app.user.email);
					m.setRecipient(app.user.getAmap().contact.email);
					var text = app.user.getName() + " vient de saisir la fiche d'une nouvelle personne dans l'AMAP : <br/><strong>" + u.getCoupleName() + "</strong><br/> <a href='http://www.cagette.net/member/view/" + u.id + "'>voir la fiche</a> ";
					m.setHtmlBody('mail/message.mtt', { text:text } );
					m.send();
				}
				
				throw Ok('/member/','Cette personne a bien été enregistrée');
				
			}
			
			
			
		}
		
		view.form = form;
	
		
	}
	
}