import db.User;
#if neko
import neko.Web;
#else
import php.Web;
#end

class App extends sugoi.BaseApp {

	public static var current : App = null;
	public static var t : sugoi.i18n.translator.ITranslator;
	public static var config = sugoi.BaseApp.config;
	
	public var eventDispatcher :hxevents.Dispatcher<event.Event>;	
	public var plugins : Array<plugin.IPlugIn>;
	
	public static function main() {
		
		App.t = sugoi.form.Form.translator = new sugoi.i18n.translator.TMap(getTranslationArray(), "fr");
		sugoi.BaseApp.main();
	}
	
	/**
	 * Init les plugins et le dispatcher juste avant de faire tourner l'app
	 */
	override public function mainLoop() {
		App.current.eventDispatcher = new hxevents.Dispatcher<event.Event>();
		App.current.plugins = [];
		#if plugins
		//Gestion expérimentale de plugin. Si ça ne complile pas, commentez les lignes ci-dessous
		App.current.plugins.push( new hosted.HostedPlugIn() );
		#end
	
		super.mainLoop();
	}
	
	override function setCookie( oldCookie : String ) {
	
		if( session != null && session.sid != null && session.sid != oldCookie ) {
			Web.setHeader("Set-Cookie", cookieName+"=" + session.sid + "; path=/;");
			//neko.Web.setHeader("Set-Cookie", cookieName+"="+session.sid+"; Domain=" + cookieDomain + "; path=/;");
			//neko.Web.setCookie(cookieName, session.sid, new Date(1970,1,1,0,0,0), cookieDomain,"/"); //delete this fucking cookie .app.cagette.net //nope, sur IE, setter deux cookie foire tout
		}
	}
	
	public function getPlugin(name:String):plugin.IPlugIn {
		for (p in plugins) {
			if (p.getName() == name) return p;
		}
		return null;
	}
	
	public static function log(t:Dynamic) {
		if (App.config.DEBUG) {
			#if neko
			Web.logMessage(Std.string(t));
			#end
			//Weblog.log(t);
		}
	}
	
	/**
	 * pour feeder l'object de traduction des formulaires
	 */
	public static function getTranslationArray() {
	
		var out = new Map<String,String>();
		out.set("firstName", "Prénom");
		out.set("lastName", "Nom");
		out.set("firstName2", "Prénom du conjoint");
		out.set("lastName2", "Nom du conjoint");
		out.set("email2", "e-mail du conjoint");
		out.set("address1", "adresse");
		out.set("address2", "adresse");
		out.set("zipCode", "code postal");
		out.set("city", "commune");
		out.set("phone", "téléphone");
		out.set("phone2", "téléphone du conjoint");
		out.set("select", "sélectionnez");
		out.set("contract", "Contrat");
		out.set("place", "Lieu");
		out.set("name", "Nom");
		out.set("cdate", "Date d'entrée dans l'Amap");
		out.set("quantity", "Quantité");
		out.set("paid", "Payé");
		out.set("user2", "(facultatif) partagé avec ");
		out.set("product", "Produit");
		out.set("user", "Adhérent");
		out.set("txtIntro", "Texte de présentation de l'Amap");
		out.set("txtHome", "Texte en page d'accueil pour les adhérents connectés");
		out.set("txtDistrib", "Texte à faire figurer sur les listes d'émargement lors des distributions");
		out.set("distributor1", "Distributeur 1");
		out.set("distributor2", "Distributeur 2");
		out.set("distributor3", "Distributeur 3");
		out.set("distributor4", "Distributeur 4");
		out.set("distributorNum", "Nbre de distributeurs nécéssaires (de 0 à 4)");
		out.set("startDate", "Date de début");
		out.set("endDate", "Date de fin");
		out.set("contact", "Reponsable");
		out.set("vendor", "Producteur");
		out.set("text", "Texte");
		out.set("flags", "Options");
		out.set("4h", "Recevoir des notifications par email 4h avant les distributions");
		out.set("24h", "Recevoir des notifications par email 24h avant les distributions");
		out.set("HasMembership", "Gestion des adhésions");
		out.set("DayOfWeek", "Jour de la semaine");
		out.set("Monday", "Lundi");
		out.set("Tuesday", "Mardi");
		out.set("Wednesday", "Mercredi");
		out.set("Thursday", "Jeudi");
		out.set("Friday", "Vendredi");
		out.set("Saturday", "Samedi");
		out.set("Sunday", "Dimanche");
		out.set("cycleType", "Récurrence");
		out.set("Weekly", "hebdomadaire");
		out.set("Monthly", "mensuelle");
		out.set("BiWeekly", "toutes les deux semaines");
		out.set("TriWeekly", "toutes les 3 semaines");
		out.set("price", "prix TTC");
		out.set("uname", "Nom");
		out.set("pname", "Produit");
		out.set("membershipRenewalDate", "Adhésions : Date de renouvellement");
		out.set("membershipPrice", "Adhésions : Coût de l'adhésion");
		out.set("UsersCanOrder", "Les adhérents peuvent saisir leur commande en ligne");
		out.set("StockManagement", "Gestion des stocks");
		out.set("contact", "Responsable");
		out.set("PercentageOnOrders", "Ajouter des frais au pourcentage de la commande");
		out.set("percentageValue", "Pourcentage des frais");
		out.set("percentageName", "Libellé pour ces frais");
		out.set("fees", "frais");
		out.set("AmapAdmin", "Accès à la gestion d'Amap");
		out.set("Membership", "Accès à la gestion des adhérents");
		out.set("Messages", "Accès à la messagerie");
		out.set("vat", "TVA");
		out.set("desc", "Description");
		out.set("ShopMode", "Mode boutique");
		out.set("IsAmap", "Votre groupe est une AMAP");
		out.set("ref", "Référence");
		return out;
	}
	
	
	public function populateAmapMembers() {		
		return user.amap.getMembersFormElementData();
	}
	
	public static function getMailer() {
		if (config.get("smtp_host") == null) throw "missing SMTP config";
		
		return new ufront.mailer.SmtpMailer(
		{
			host:config.get("smtp_host"),
			port:config.getInt("smtp_port"),
			user:config.get("smtp_user"),
			pass:config.get("smtp_pass"),
		});	
	}
	
	/**
	 * process a template and returns the generated string
	 * @param	tpl
	 * @param	ctx
	 */
	public function processTemplate(tpl:String, ctx:Dynamic):String {
		Reflect.setField(ctx, 'HOST', App.config.HOST);
		
		var tpl = loadTemplate(tpl);
		var html = tpl.execute(ctx);	
		#if php
		if ( html.substr(0, 4) == "null") html = html.substr(4);
		#end
		return html;
	}
	
}