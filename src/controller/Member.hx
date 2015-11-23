package controller;
import db.UserContract;
import haxe.Utf8;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import sugoi.form.validators.EmailValidator;
#if neko
import neko.Web;
#else
import php.Web;
#end
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
	function doDefault(?args: { ?search:String, ?select:String } ) {
		checkToken();
		
		var browse:Int->Int->List<Dynamic>;
		var uids = db.UserAmap.manager.search($amap == app.user.getAmap(), false);
		var uids = Lambda.map(uids, function(ua) return ua.user.id);
		if (args != null && args.search != null) {
			
			//SEARCH
			
			browse = function(index:Int, limit:Int) {
				var search = StringTools.trim(args.search);
				return db.User.manager.search( ($lastName.like(search)||$lastName2.like(search)) && $id in uids , { orderBy:-id }, false);
			}
			view.search = args.search;
			
		}else if(args!=null && args.select!=null){
			
			//SELECTION
			
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
				case "newusers" :
					if (app.params.exists("csv")) {
						setCsvData(Lambda.array(db.User.getUsers_NewUsers()), ["firstName", "lastName", "email"], "jamais-connecté");
						return;
					}else {
						browse = function(index:Int, limit:Int) { return db.User.getUsers_NewUsers(index, limit); }
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
		var rb = new sugoi.tools.ResultsBrowser(count, (args.select!=null||args.search!=null)?1000:10, browse);
		view.members = rb;
		
		if (args.select == null || args.select != "newusers") {
			//count new users
			view.newUsers = db.User.getUsers_NewUsers().length;	
		}
		
		
	}
	
	/**
	 * Invite 'never logged' users
	 */
	function doInvite() {
		
		if (checkToken()) {
			
			var users = db.User.getUsers_NewUsers();
			for ( u in users) {
				u.sendInvitation();
				Sys.sleep(0.2);
			}
			
			throw Ok('/member', "Bravo, vous avez envoyé <b>" + users.length + "</b> invitations.");
		}
		
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
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == app.user.amap && $endDate > DateTools.delta(Date.now(),-1000.0*60*60*24*30), false);
		var orders = member.getOrdersFromContracts(contracts);
		row.constOrders = Lambda.array(orders);
		
		//commandes variables groupées par date de distrib
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == app.user.amap && $endDate > DateTools.delta(Date.now(),-1000.0*60*60*24*30), false);
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
		view.userContracts = row;
		
		checkToken(); //to insert a token in tpl
		
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
		
		if (member.isAdmin() && !app.user.isAdmin()) throw Error("/","Vous ne pouvez pas modifier le compte d'un administrateur");
		
		var form = sugoi.form.Form.fromSpod(member);
		
		//cleaning
		form.removeElement( form.getElement("pass") );
		form.removeElement( form.getElement("rights") );
		form.removeElement( form.getElement("lang") );		
		form.removeElement( form.getElement("ldate") );
		form.getElement("email").addValidator(new EmailValidator());
		form.getElement("email2").addValidator(new EmailValidator());
		
		
		
		if (form.checkToken()) {
			
			//vérifie si mails pas déjà 
			var sim = db.User.getSimilar(form.getValueOf("firstName"), form.getValueOf("lastName"), form.getValueOf("email"), form.getValueOf("firstName2"), form.getValueOf("lastName2"), form.getValueOf("email2"));
			for ( s in sim) {				
				if (s.id == member.id) sim.remove(s);
			}
			if (sim.length>0) {
				throw Error("/member/edit/" + member.id, "Attention, Cet email ou ce nom existe déjà dans une autre fiche : "+Lambda.map(sim,function(u) return "<a href='/member/view/"+u.id+"'>"+u.getCoupleName()+"</a>").join(","));
			}
			
			//verif changement d'email
			if (form.getValueOf("email") != member.email) {
				var mail = new sugoi.mail.MandrillApiMail();
				mail.setSender("noreply@cagette.net");
				mail.setRecipient(member.email);
				mail.setSubject("Changement d'email sur votre compte Cagette.net");
				mail.setHtmlBody("mail/message.mtt", { text:app.user.getName() + " vient de modifier votre email sur votre fiche Cagette.net.<br/>Votre email est maintenant : "+form.getValueOf("email") } );			
				mail.send();	
			}
			if (form.getValueOf("email2") != member.email2 && member.email2!=null) {
				var mail = new sugoi.mail.MandrillApiMail();
				mail.setSender("noreply@cagette.net");
				mail.setRecipient(member.email2);
				mail.setSubject("Changement d'email sur votre compte Cagette.net");
				mail.setHtmlBody("mail/message.mtt", { text:app.user.getName() + " vient de modifier votre email sur votre fiche Cagette.net.<br/>Votre email est maintenant : "+form.getValueOf("email2") } );			
				mail.send();	
			}
			
			//update model
			form.toSpod(member); 
			
			//lower / upper case
			member.lastName = member.lastName.toUpperCase();
			if (member.lastName2 != null) member.lastName2 = member.lastName2.toUpperCase();
			//member.email = member.email.toLowerCase();
			//if(member.email2
			
			
			member.update();
			throw Ok('/member/view/'+member.id,'Ce membre a été mis à jour');
		}
		
		view.form = form;
	}
	
	/**
	 * Remove a user from this group
	 */
	function doDelete(user:db.User,?args:{confirm:Bool,token:String}) {
		
		if (checkToken()) {
			if (!app.user.isContractManager()) throw "Vous ne pouvez pas faire ça.";
			if (user.id == app.user.id) throw Error("/member/view/"+user.id,"Vous ne pouvez pas vous effacer vous même.");
			if ( user.getOrders(app.user.amap).length > 0 && !args.confirm) throw Error("/member/view/"+user.id,"Attention, ce compte a des commandes en cours. <a class='btn btn-default btn-xs' href='/member/delete/"+user.id+"?token="+args.token+"&confirm=1'>Effacer quand-même</a>");
		
		
			var ua = db.UserAmap.get(user, app.user.amap, true);
			if (ua != null) {
				ua.delete();
				throw Ok("/member", user.getName() + " a bien été supprimé(e) de votre groupe");
			}else {
				throw Error("/member", "Cette personne ne fait pas partie de \"" + app.user.amap.name+"\"");			
			}	
		}else {
			throw Redirect("/member/view/"+user.id);
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
			var contracts = db.UserContract.manager.search($user==m2 || $user2==m2,true);
			for (c in contracts) {
				if (c.user.id == m2.id) c.user = m1;
				if (c.user2!=null && c.user2.id == m2.id) c.user2 = m1;
				c.update();
			}
			
			//group memberships
			var adh = db.UserAmap.manager.search($user == m2, true);
			for ( a in adh) {
				a.user = m1;
				a.update();
			}
			
			//change contacts
			var contacts = db.Contract.manager.search($contact==m2,true);
			for (c in contacts) {
				c.contact = m1;
				c.update();
			}
			//if (m2.amap.contact == m2) {
				//m1.amap.lock();
				//m1.amap.contact = m1;
				//m1.amap.update();
			//}
			
			m2.delete();
			
			throw Ok("/member/view/" + m1.id, "Les deux comptes ont été fusionnés");
			
			
		}
		
		view.form = form;
		
	}
	
	
	@tpl('member/import.mtt')
	function doImport(?args:{confirm:Bool}) {
			
		var step = 1;
		var request = Utils.getMultipart(1024 * 1024 * 4); //4mb
		
		//on recupere le contenu de l'upload
		var data = request.get("file");
		if ( data != null) {
			
			var csv = new sugoi.tools.Csv();
			var unregistred = csv.importDatas(data);
			
			/*var t = new sugoi.helper.Table("table");
			trace(t.toString(unregistred));*/
			
			//cleaning
			for ( user in unregistred.copy() ) {
				
				//check nom+prenom
				if (user[0] == null || user[1] == null) throw "Vous devez remplir le nom et prénom de la personne. <br/>Cette ligne est incomplète : " + user;
				if (user[2] == null) throw "Chaque personne doit avoir un email, sinon elle ne pourra pas se connecter. "+user[0]+" "+user[1]+" n'en a pas.";
				//uppercase du nom
				if(user[1]!=null) user[1] = user[1].toUpperCase();
				if (user[5] != null) user[5] = user[5].toUpperCase();
				
				App.log(user);
			}
			
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
				var email = r[2];
				var firstName2 = r[4];
				var lastName2 = r[5];
				var email2 = r[6];
				
				var us = db.User.getSimilar(firstName, lastName, email, firstName2, lastName2, email2);
				
				
				/*var us = db.User.manager.search(
					(
					
						($firstName.like(firstName) && $lastName.like(lastName)) || 
						($firstName2!=null && $firstName2.like(firstName) && $lastName2.like(lastName)) ||
						
						($firstName.like(firstName2) && $lastName.like(lastName2)) || 
						($firstName2!=null && $firstName2.like(firstName2) && $lastName2.like(lastName2)) ||
						
						($email.like(r[2])) ||
						($email2!=null && $email2.like(r[2])) ||
						($email.like(r[6])) ||
						($email2!=null && $email2.like(r[6]))
					)
					
				,false);*/
				if (us.length > 0) {
					//trace(r[0]+" "+r[1]+" existe deja : "+us);
					unregistred.remove(r);
					registred.push(r);
				}
			}
			
			
			app.session.data.csvUnregistered = unregistred;
			app.session.data.csvRegistered = registred;
			
			view.data = unregistred;
			view.data2 = registred;
			step = 2;
		}
		
		
		if (args != null && args.confirm) {
			
			//import unregistered members
			var i : Iterable<Dynamic> = cast app.session.data.csvUnregistered;
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
			
			//import registered members
			var i : Iterable<Dynamic> = cast app.session.data.csvRegistered;
			for (u in i) {
				var firstName = u[0];
				var lastName = u[1];
				var email = u[2];
				var firstName2 = u[4];
				var lastName2 = u[5];
				var email2 = u[6];
				
				var us = db.User.getSimilar(firstName, lastName, email, firstName2, lastName2, email2);
				var userAmaps = db.UserAmap.manager.search($amap == app.user.amap && $userId in Lambda.map(us, function(u) return u.id), false);
				
				if (userAmaps.length == 0) {
					//il existe dans cagette, mais pas pour ce groupe
					var ua = new db.UserAmap();
					ua.user = us.first();
					ua.amap = app.user.amap;
					ua.insert();
				}
				
				
			}
			
			view.numImported = app.session.data.csvUnregistered.length + app.session.data.csvRegistered.length;
			app.session.data.csvUnregistered = null;
			app.session.data.csvRegistered = null;
			
			step = 3;
		}
		
		if (step == 1) {
			//reset import when back to import page
			app.session.data.csvUnregistered = null;
			app.session.data.csvRegistered = null;
		}
		
		view.step = step;
	}
	
	@tpl("user/insert.mtt")
	public function doInsert() {
		
		var e = new event.Event();
		e.id = "wantToAddMember";
		App.current.eventDispatcher.dispatch(e);
		
		var m = new db.User();
		var form = sugoi.form.Form.fromSpod(m);
		form.removeElement(form.getElement("lang"));
		form.removeElement(form.getElement("rights"));
		form.removeElement(form.getElement("pass"));	
		form.removeElement(form.getElement("ldate") );
		form.addElement(new sugoi.form.elements.Checkbox("warnAmapManager", "Envoyer un mail au responsable du groupe", true));
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
				throw Error('/member/view/' + userAmaps.first().user.id, 'Cette personne est déjà inscrite dans ce groupe');
				
			}else if (userSims.length > 0) {
				//des users existent avec ce nom , 
				if (userSims.length == 1) {
					// si yen a qu'un on l'inserte
					var ua = new db.UserAmap();
					ua.user = userSims.first();
					ua.amap = app.user.amap;
					ua.insert();	
					throw Ok('/member/','Cette personne était déjà inscrite sur Cagette.net, nous l\'avons inscrite à votre groupe.');
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
					m.setSubject(app.user.amap.name+" - Nouvel inscrit : " + u.getCoupleName());
					m.setSender(app.user.email);
					m.setRecipient(app.user.getAmap().contact.email);
					var text = app.user.getName() + " vient de saisir la fiche d'une nouvelle personne  : <br/><strong>" + u.getCoupleName() + "</strong><br/> <a href='http://www.cagette.net/member/view/" + u.id + "'>voir la fiche</a> ";
					m.setHtmlBody('mail/message.mtt', { text:text } );
					m.send();
				}
				
				throw Ok('/member/','Cette personne a bien été enregistrée');
				
			}
		}
		
		view.form = form;
	
		
	}
	
}