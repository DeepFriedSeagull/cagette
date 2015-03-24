package controller;
import haxe.crypto.Md5;
import sugoi.form.elements.Hidden;
import sugoi.form.elements.Input;
import sugoi.form.Form;
import sugoi.form.validators.EmailValidator;
import neko.Web;


class User extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("user/default.mtt")
	function doDefault() {
		
	}
	
	
	@tpl("user/login.mtt")
	function doLogin(?args: { name:String, pass:String } ) {
		
		if (App.current.user != null) throw Redirect('/');
		
		if (args != null) {
			var pass = Md5.encode( App.config.get('key') + StringTools.trim(args.pass));
			var user = db.User.manager.select( ($email == StringTools.trim(args.name) || $email2 ==StringTools.trim(args.name) ) && $pass == pass, true);
			if (user == null) {
				//empty pass
				user = db.User.manager.select( ($email == StringTools.trim(args.name) || $email2 ==StringTools.trim(args.name) ) && $pass == "", true);
				if (user == null) {
					throw Error("/user/login", "email ou mot de passe incorrect");	
				}
			}
			
			user.ldate = Date.now();
			user.update();
			App.current.session.setUser(user);
			
			//sugoi.db.Session.clean();
			
			if (user.getAmap() == null) {
				throw Ok("/user/choose/", "Bonjour " + user.firstName+" !");
			}else {				
				throw Ok("/", "Bonjour " + user.firstName+" !");
			}
			
		}
	}
	
	@tpl("user/choose.mtt")
	function doChoose(?args:{amap:db.Amap}) {
		var amaps = db.UserAmap.manager.search($user == app.user, false);
		if (amaps.length == 0) throw "Vous ne faites partie d'aucune AMAP";
		if (amaps.length == 1) {
			//qu'une amap
			app.session.data.amapId = amaps.first().amapId;
			throw Redirect('/');
		}
		
		if (args!=null && args.amap!=null) {
			//selectionne une amap
			app.session.data.amapId = args.amap.id;
			throw Redirect('/');
		}
		
		view.amaps = amaps;
	}
	
	function doLogout() {
		App.current.session.delete();
		throw Redirect('/');
	}
	
	/**
	 * ask for password renewal by mail
	 * when password is forgotten
	 */
	@tpl("user/forgottenPassword.mtt")
	function doForgottenPassword(?key:String,?u:db.User){
		var step = 1;
		var error : String = null;
		var url = "/user/forgottenPassword";
		
		//ask for mail
		var askmailform = new Form("askemail");
		askmailform.addElement(new Input("email","Saisissez votre email"));
	
		//change pass form
		var chpassform = new Form("chpass");
		chpassform.addElement(new Input("pass1","Votre nouveau mot de passe"));
		chpassform.addElement(new Input("pass2", "Retapez votre mot de passe pour vérification"));
		chpassform.addElement(new Hidden("uid", u == null?'':Std.string(u.id)));
		
		if (askmailform.isValid()) {
			//send password renewal email
			step = 2;
			
			var email = askmailform.getValueOf("email");
			var user = db.User.manager.select(email == $email, false);
			
			if (user == null) throw Error(url, "Cet email n'est lié à aucun compte connu");
			
			
			var m = new sugoi.mail.MandrillApiMail();
			m.setSender(App.config.get("webmaster_email"), App.config.get("webmaster_name"));
			m.addRecipient(user.email, user.name, user.id);
			m.title = App.config.NAME+" : Changement de mot de passe";
			m.setHtmlBody('mail/forgottenPassword.mtt', { user:user, link:'http://' + App.config.HOST + '/user/forgottenPassword/'+m.getKey()+"/"+user.id } );
			m.send();
		}
		
		if (key != null && u!=null) {
			//check key and propose to change pass
			step = 3;
			
			var m = new sugoi.mail.MandrillApiMail();
			m.addRecipient(u.email, u.name, u.id);
			if (m.getKey() == key) {
				view.form = chpassform;
			}else {
				error = "bad request";
			}
			
			
		}
		
		
		if (chpassform.isValid()) {
			//change pass
			step = 4;
			
			if ( chpassform.getValueOf("pass1") == chpassform.getValueOf("pass2")) {
				
				var uid = Std.parseInt( chpassform.getValueOf("uid") );
				var user = db.User.manager.get(uid, true);
				user.setPass(chpassform.getValueOf("pass1"));
				user.update();
				
			}else {
				error = "Vous devez saisir deux fois le même mot-de-passe";
			}
		}
			
		if (step == 1) {
			view.form = askmailform;
		}
		
		view.step = step;
		view.error = error;

	}
	
	/*@tpl('user/register.mtt')
	function doRegister() {
		
		var form = new Form('register',null,FormMethod.GET);
		form.addElement(new Input('name', 'Your nickname'));
		var pass1 = new Input('pass1', 'Your password');
		pass1.password = true;
		form.addElement(pass1);
		var pass2 = new Input('pass2', 'Please enter your password again');
		pass2.password = true;
		form.addElement(pass2);
		var email = new Input('email', 'Your e-mail');
		//email.addValidator(new EmailValidator());
		form.addElement(email);
		
		if(form.isSubmitted()){
			if (form.isValid()) {
				
				if (form.getValueOf('pass1') != form.getValueOf('pass2')) {
					throw Error('/user/register', 'Please enter the same password twice');
				}
				var user = new db.User();
				user.name = form.getValueOf('name');
				user.pass = Md5.encode( App.config.get('key') + form.getValueOf('pass1') );
				user.email = form.getValueOf('email');
				user.insert();
				
				//TODO : send an email
				
				throw Ok('/user/login', 'Congratulations ! <br/> You can now log into ' + App.config.NAME);
				
			}else {
				throw Error('/', 'Error');
			}
		}
		view.form = form;
		
	}*/
	
	
	@tpl("form.mtt")
	function doRegister() {
		
		if (App.current.user != null) throw Redirect('/');
		
		view.title = "Essayez Cagette.net";
		view.text = "Vous êtes sur le point de vous créer un compte de test sur Cagette.net.<br/>Ce compte sera limité à 20 adhérents mais vous pourrez passer à tout moment à des abonements de niveau supérieur.";
		
		var f = new sugoi.form.Form("c");
		f.addElement(new sugoi.form.elements.Input("amapName", "Nom de votre groupement"));
		f.addElement(new sugoi.form.elements.Input("userFirstName", "Votre prenom"));
		f.addElement(new sugoi.form.elements.Input("userLastName", "Votre nom de famille"));
		f.addElement(new sugoi.form.elements.Input("userEmail", "Votre email"));
		
		if (f.checkToken()) {
			
			var user = new db.User();
			user.email = f.getValueOf("userEmail");
			user.firstName = f.getValueOf("userFirstName");
			user.lastName = f.getValueOf("userLastName");
			user.pass = "859738d2fed6a98902defb00263f0d35";
			user.insert();
			
			var amap = new db.Amap();
			amap.name = f.getValueOf("amapName");
			amap.contact = user;
			amap.insert();
			
			var ua = new db.UserAmap();
			ua.user = user;
			ua.amap = amap;
			ua.rights = [db.UserAmap.Right.AmapAdmin,db.UserAmap.Right.Membership,db.UserAmap.Right.Messages,db.UserAmap.Right.ContractAdmin(null)];
			ua.insert();
			
			//example datas
			var place = new db.Place();
			place.name = "Place du marché";
			place.amap = amap;
			place.insert();
			
			var vendor = new db.Vendor();
			vendor.amap = amap;
			vendor.name = "Jean Martin EURL";
			vendor.insert();
			
			var contract = new db.Contract();
			contract.name = "Contrat Maraîcher Exemple";
			contract.amap  = amap;
			contract.type = 0;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.insert();
			
			var p = new db.Product();
			p.name = "Gros panier de légumes";
			p.price = 15;
			p.contract = contract;
			p.insert();
			
			var p = new db.Product();
			p.name = "Petit panier de légumes";
			p.price = 10;
			p.contract = contract;
			p.insert();
		
			var uc = new db.UserContract();
			uc.user = user;
			uc.product = p;
			uc.amap = amap;
			uc.paid = true;
			uc.quantity = 1;
			uc.insert();
			
			var d = new db.Distribution();
			d.contract = contract;
			d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
			d.place = place;
			d.insert();
			
			App.current.user = null;
			App.current.session.setUser(user);
			App.current.session.data.amapId  = amap.id;
			
			throw Ok("/", "Amap créée");
			
			
			
			
		}
		
		view.form= f;
		
	}
	
	
	@tpl("form.mtt")
	function doDefinePassword(?key:String,?u:db.User){
		if (app.user.pass != "859738d2fed6a98902defb00263f0d35") throw Error("/","Vous avez déjà un mot de passe");

		var form = new Form("definepass");
		form.addElement(new Input("pass1","Votre nouveau mot de passe"));
		form.addElement(new Input("pass2", "Retapez votre mot de passe pour vérification"));
		
		
		if (form.isValid()) {
			
			if ( form.getValueOf("pass1") == form.getValueOf("pass2")) {
				
				app.user.lock();
				app.user.setPass(form.getValueOf("pass1"));
				app.user.update();
				throw Ok('/', "Bravo, votre compte est maintenant protégé par un mot de passe.");
				
			}else {
				form.addError("Vous devez saisir deux fois le même mot-de-passe");
			}
		}
		view.form = form;
		view.title = "Définissez un mot de passe pour votre compte";
	}
	
	
	
}