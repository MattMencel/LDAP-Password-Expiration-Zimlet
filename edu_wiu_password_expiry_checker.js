function edu_wiu_password_expiry_checker() { };

edu_wiu_password_expiry_checker.prototype = new ZmZimletBase();
edu_wiu_password_expiry_checker.prototype.constructor = edu_wiu_password_expiry_checker;
edu_wiu_password_expiry_checker.prototype.init = function() {
    try { console.info( '[ZIMLET] edu_wiu_password_expiry_checker has loaded' ); } catch (err) {}
	// connect to your ldap, check the password expiry date
	var reqParam = 'action=getpwexp';
	var urlStr = this.getResource("ldap.jsp");
	var url = AjxStringUtil.urlEncode(urlStr);
	var result=AjxRpc.invoke(null, url + "?" + reqParam, null, null, true);
	this.xmlDoc = result.xml;
	var xmlDoc = this.xmlDoc;
	
	var expiryDate = "20500101000000Z"
	var todaysDate = new Date();
	
	if (this.qXml("length","pwdChangedTime") == 0 ) {
		expiryDate = "20091029000000Z";
	}
	else if (this.qXml("length","passwordExpirationTime") !=0 ) {
		expiryDate = this.qXml("value","passwordExpirationTime");
	}
	
	var yyyy = expiryDate.substring(0,4);
	var mo = expiryDate.substring(4,6);
	var da = expiryDate.substring(6,8);
	var hh = expiryDate.substring(8,10);
	var mm = expiryDate.substring(10,12);
	var ss = expiryDate.substring(12,14);
        //Month needs to be converted to UNIX format(mo-1)
	var willExpire = new Date(Date.UTC(yyyy,mo-1,da,hh,mm,ss));

	willExpire = willExpire - todaysDate;

	if ((willExpire <= 1209600000)&&(willExpire>0)) {
		//expiration less than 14 days away
		willExpire = this.convertMilliseconds(willExpire);
		this.showExpiryMessage(willExpire);
	}	
};

edu_wiu_password_expiry_checker.prototype.checkForPluralTime = function(varname,varval) {
	var text = "";
	if (varval == 0) {text = "";}
		else if (varval == 1) {text = varval + " " + varname.substring(0,varname.length-1) + ", ";}
		else {text = varval + " " + varname + ", ";}
	return text;
};

edu_wiu_password_expiry_checker.prototype.convertMilliseconds = function(millisecs) {
	if (millisecs <= 60000) {return " less than 60 seconds";}
	var x = millisecs/1000;
	var seconds = Math.floor(x%60);
	seconds = this.checkForPluralTime("seconds", seconds);
	x = x/60;
	var minutes = Math.floor(x%60);
	minutes = this.checkForPluralTime("minutes", minutes);
	minutes = minutes.substring(0,minutes.length-2); //strip trailing ", " from minutes
	x = x/60;
	var hours = Math.floor(x%24);
	hours = this.checkForPluralTime("hours", hours);
	x = x/24;
	var days = Math.floor(x);
	days = this.checkForPluralTime("days", days);
	return days+hours+minutes;//+seconds+" seconds";
};

edu_wiu_password_expiry_checker.prototype.showExpiryMessage = function(expiryDate) {
    try { console.info( 'showExpiryMessage' ); } catch (err) {}
    var view = new DwtComposite(this.getShell());
	var el = view.getHtmlElement();
	var div = document.createElement("div");   
	var html=new Array();
	var i=0;
	html[i++] = '<p><center>Your password will expire in '+ expiryDate +'.<br/>Please go to <a href="http://www.wiu.edu/guava" target=_new>GUAVA</a> to change it as soon as possible.</p><br/>';
	//html[i++] = '<a href="https://www.wiu.edu/utech/passwordChange" target="_blank"><img src="./more_info.png"></a>'
	html[i++] = '<button target="_blank" onclick="location.href=\'https://www.wiu.edu/utech/passwordChange\'"><div align="center"><b> More Info </div></button>';
	html[i++] = '&nbsp&nbsp&nbsp&nbsp&nbsp'
	html[i++] = '<button target="_blank" onclick="location.href=\'https://www.wiu.edu/guava/password.sphp\'"><div align="center"><b> Change Password </div></button></center>';
	div.innerHTML = html.join('');
	 
    el.appendChild(div);
    var dialog_args = {
        title	: "Password Expiration Notice",
        view	: view
    };
    var dlg = this._createDialog(dialog_args);
    dlg.getButton(DwtDialog.OK_BUTTON).setText("Close");
    dlg.setButtonVisible(DwtDialog.CANCEL_BUTTON, false);
    // dlg.setButtonListener block is optional; you can use it to augment the default OK button handler 
    // (popdown, dispose) to do interesting things like set a flag somewhere that the user has been notified, etc. 
    // As it is below, it duplicates the default OK button handler.
    dlg.setButtonListener(DwtDialog.OK_BUTTON, new AjxListener(this, function() {
        dlg.popdown();
        dlg.dispose();
    }));

	// var infoButtonId = Dwt.getNextId();
	// this._infoButton = new DwtDialog_ButtonDescriptor(infoButtonId, "More Info");
	// var chpassButtonId = Dwt.getNextId();
	// this._chpassButton = new DwtDialog_ButtonDescriptor(chpassButtonId, "Change Password");
	//     var dialog_args = {
	//         title	: "Password Expiration Notice",
	//         view	: view
	// 	standardButtons: [DwtDialog.DISMISS_BUTTON],
	// 	extraButtons: [this._infoButton, this._chpassButton]
	//     };
	//     var dlg = this._createDialog(dialog_args);
	// 	dlg.setButtonListener(infoButtonId, new AjaxListener(this, this.dlgButtonHandler, "info"));
	// 	dlg.setButtonListener(chpassButtonId, new AjaxListener(this, this.dlgButtonHandler, "chpass"));
	// 	dlg.setButtonListener(chpassButtonId, new AjaxListener(this, this.dlgButtonHandler, ""));
    dlg.popup();
};

edu_wiu_password_expiry_checker.prototype.qXml = function(mode,key) {
	if (mode == "length") {
		return parseInt(this.xmlDoc.getElementsByTagName(key).length);
	}
	else if (mode == "value") {
		return this.xmlDoc.getElementsByTagName(key)[0].childNodes[0].nodeValue;
	}
	else {
		return;
	}
};

edu_wiu_password_expiry_checker.prototype.dlgButtonHandler = function(action) {
	this._dlg.popdown();
	this._dlg.dispose();
	switch(action) {
		case "info":
			window.open(infoURL, "More Info");
			break;
		case "chpass":
			window.optn(chpassURL, "Change Password");
			break;
	}
};
