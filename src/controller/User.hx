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
					throw Error("/user/login", "Email ou mot de passe incorrect");	
				}
			}
			
			user.ldate = Date.now();
			user.update();
			App.current.session.setUser(user);
			App.current.session.data.whichUser = (args.name == user.email) ? 0 : 1; //qui est connecté, monsieur ou madame ?
			
			//sugoi.db.Session.clean();
			
			if (user.getAmap() == null) {
				throw Redirect("/user/choose/");
			}else {				
				throw Ok("/", "Bonjour " + (args.name == user.email ? user.firstName : user.firstName2)+" !");
			}
			
		}
	}
	
	@tpl("user/choose.mtt")
	function doChoose(?args: { amap:db.Amap } ) {
		if (app.user == null) throw "Vous n'êtes pas connecté";
		var amaps = db.UserAmap.manager.search($user == app.user, false);
		
		if (amaps.length == 0) throw "Vous ne faites partie d'aucun groupe";
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