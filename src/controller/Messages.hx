package controller;
import db.Message;
import db.UserContract;
import sugoi.form.validators.EmailValidator;
import sugoi.form.elements.*;
import sugoi.form.Form;

class Messages extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.canAccessMessages()) throw Redirect("/");
	}
	
	@tpl("messages/default.mtt")
	function doDefault() {
		
		var form = new Form("msg");
		var lists = getLists();
		form.addElement( new Selectbox("list", "Destinataires",lists,null,false,null,"style='width:500px;'"));
		form.addElement( new Input("subject", "Sujet :","",false,null,"style='width:500px;'") );
		form.addElement( new TextArea("text", "Message :", "", false, null, "style='width:500px;height:350px;'") );
		
		
		
		if (form.checkToken()) {
			
			var mail = new sugoi.mail.MandrillApiMail();
			var listId = form.getElement("list").value;
			var dest = getSelection(listId);
		
			var mails = [];
			for ( d in dest) {
				if (d.email != null) mails.push(d.email);
				if (d.email2 != null) mails.push(d.email2);
			}
			
			//mails
			//for( m in mails) mail.addRecipient(m);
			//mail.setSender(app.user.email, app.user.firstName+" "+app.user.lastName);
			//mail.title = form.getElement("subject").value;
			//var text :String = form.getElement("text").value;
			//mail.setHtmlBody('mail/message.mtt', { text:text } );
			
			
			//send mail confirmation link
			var e = new ufront.mail.Email();		
			e.setSubject(form.getValueOf("subject"));
			e.bcc(Lambda.map(mails, function(m) return new ufront.mail.EmailAddress(m)));
			
			if (App.current.session.data.whichUser == 1) {
				e.from(new ufront.mail.EmailAddress("noreply@cagette.net",app.user.firstName2 + " " + app.user.lastName2));		
				e.replyTo(new ufront.mail.EmailAddress(app.user.email2, app.user.firstName2 + " " + app.user.lastName2));
			}else {				
				e.from(new ufront.mail.EmailAddress("noreply@cagette.net",app.user.firstName+" " + app.user.lastName));		
				e.replyTo(new ufront.mail.EmailAddress(app.user.email, app.user.firstName+" " + app.user.lastName));		
			}
			
			var text :String = form.getValueOf("text");
			var html = app.processTemplate("mail/message.mtt", { text:text,group:app.user.amap,list:getListName(listId) });		
			e.setHtml(html);
			
			
			
			var event = new event.MessageEvent();
			event.id = "sendMessage";
			event.message = mail;
			App.current.eventDispatcher.dispatch(event);
			
			App.getMailer().send(e);
			
			var m = new db.Message();
			m.sender = app.user;
			m.title = e.subject;
			m.body = e.html;
			m.date = Date.now();
			m.amap = app.user.amap;
			m.recipientListId = listId;
			m.insert();
			
			throw Ok("/messages", "Le message a bien été envoyé");
		}
		
		view.form = form;
		
		if (app.user.isAmapManager()) {
			view.sentMessages = Message.manager.search($amap == app.user.amap, {orderBy:-date,limit:20}, false);
		}else {
			view.sentMessages = Message.manager.search($sender == app.user && $amap == app.user.amap, {orderBy:-date,limit:20}, false);	
		}
		
	}
	
	@tpl("messages/message.mtt")
	public function doMessage(msg:Message) {
		if (!app.user.isAmapManager() && msg.sender.id != app.user.id) throw Error("/", "accès non autorisé");
		
		var lists2 = new Map<String,String>();
		for (l in getLists()) lists2.set(l.key, l.value);
		view.lists = lists2;
		
		view.list = lists2.get(msg.recipientListId);
		view.msg = msg;
		
	}
	
	function getLists() :Array<{key:String,value:String}>{
		var out = [
			{key:'1', value:'Tout le monde' },
			{key:'2', value:'Les responsables contrat et le responsable d\'AMAP' },			
		];
		
		/*if (App.config.DEBUG)*/ out.push( { key:'3', value:'TEST : moi + conjoint(e)' } );
		out.push( { key:'4', value:'Amapiens sans contrat' } );
		if(app.user.amap.hasMembership()) out.push( { key:'5', value:'Adhésions à renouveller' } );
		
		
		var contracts = db.Contract.getActiveContracts(app.user.amap,true);
		for ( c in contracts) {
			out.push({key:'c'+c.id,value:'Souscripteurs '+c.toString()});
		}
		return out ;
		
	}
	
	/**
	 * get list name from id
	 * @param	listId
	 */
	function getListName(listId:String) {
		var l = getLists();
		
		for (ll in l) {
			if (ll.key == listId) return ll.value;
		}
		
		return null;
		
	}
	
	function getSelection(listId:String) {
		if (listId.substr(0, 1) == "c") {
			//contrats
			var contract = Std.parseInt(listId.substr(1));
			
			var pids = db.Product.manager.search($contractId == contract, false);
			var pids = Lambda.map(pids, function(x) return x.id);
			var up = db.UserContract.manager.search($productId in pids, false);
			
			
			var users = [];
			for ( order in up) {
				if (!Lambda.has(users, order.user)) {
					users.push(order.user);	
					
					if (order.user2 != null) {
						users.push(order.user2);
					}
				}
			}
			return users;
			
		}else {
			var out = [];
			switch(listId) {
			case "1": 		
				//tout le monde
				out =  Lambda.array(app.user.amap.getMembers());
					
			case "2":
				
				var users = [];
				users.push(app.user.amap.contact);
				for ( c in db.Contract.manager.search($amap == app.user.amap)) {
					if (!Lambda.has(users, c.contact)) {
						users.push(c.contact);
					}
				}
				out = users;
			
			case "3":
				//moi
				return [app.user];
			case "4":
				return Lambda.array(db.User.getUsers_NoContracts());
			case "5":
				return Lambda.array(db.User.getUsers_NoMembership());
			}
			
			return out;
			
		}
	}
	
	

	
	
}