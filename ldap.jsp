<%@ page contentType='text/xml'%>
<%@ page language="java" import="com.sun.jndi.ldap.*, java.lang.String, java.io.*, java.util.*, javax.naming.*, javax.naming.directory.*, org.apache.commons.lang.StringEscapeUtils"%>
<%@ page import="com.zimbra.cs.account.Provisioning" %>
<%@ page import="com.zimbra.cs.account.Provisioning.AccountBy" %>
<%@ page import="com.zimbra.cs.account.Account" %>
<%@ page import="com.zimbra.cs.account.AuthToken" %>


<%
final class LdapStuff{
	//Class Variable Declarations
	private String action;
	private String zimbraUid;
	private PrintWriter output;
	
	public String init(String args[], PrintWriter output){
		zimbraUid = args[0];
		action = args[1];
		output = output;
		String result = "";
		if (action.equals("getpwexp")){
			result = GetPasswordExpirationResult("(|(wiualias="+zimbraUid+")(uid="+zimbraUid+"))");
		}
		return result;
	}//end init()

	private String GetPasswordExpirationResult(String filter){
		String value = "";
		try {
			DirContext ctx = LdapConn();
	  		SearchControls searchControls = new SearchControls();
	  		searchControls.setSearchScope(SearchControls.SUBTREE_SCOPE);
			String[] attrNames = {"passwordExpirationTime","pwdChangedTime"};
			searchControls.setReturningAttributes(attrNames);
	  		NamingEnumeration results = ctx.search("dc=wiu,dc=edu", filter, searchControls);
			ctx.close();
			value = GetResultXml(results);
		}	
		catch (NamingException e){
			//Authentication Failed
			output.println("Caught Error: ");
			output.println(e);
		} //end try-catch
		
		return value;
	}
	
	private String GetResultXml(NamingEnumeration results){
		String xml = "";
		try{
			while (results.hasMoreElements()) {
				SearchResult result = (SearchResult)results.nextElement();
				Attributes attrs = result.getAttributes();

				if ( attrs != null ){
					NamingEnumeration enumer = attrs.getAll();
					Attribute attr;
					xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
					xml = xml.concat("<wiu_dir>");
					while( enumer != null && enumer.hasMore() )
					{
						attr = ( Attribute )enumer.next();
						xml=xml.concat("<"+attr.getID()+">"+attr.get().toString()+"</"+attr.getID()+">");
					}//endwhile
					xml = xml.concat("</wiu_dir>");
				}//endif

			}//endwhile
		}//endtry
		catch (Exception e){
			output.println("Exception: "+ e);
		}//endcatch
		return xml;
	}
	
	private DirContext LdapConn(){
		DirContext ctx = null;
		String ldapServerName = "xxx.xxx.xxx";
		String user = "XXXXXXX";
		String pass = "XXXXXXX";
		String dn= "cn=" . concat(user) . concat(",ou=applications,dc=wiu,dc=edu");

		Properties env = new Properties();
		env.put( Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory" );
		env.put("java.naming.ldap.version", "3");
		env.put( Context.PROVIDER_URL, "ldap://"+ ldapServerName + "/");
		env.put( Context.SECURITY_AUTHENTICATION, "simple");
		env.put( Context.SECURITY_PRINCIPAL, dn );
		env.put( Context.SECURITY_CREDENTIALS, pass );
	  
		try{
			ctx = new InitialDirContext( env );
		}
		catch (NamingException e){
			//Authentication Failed
			output.println("Caught Error: ");
			output.println(e);
		}
		return ctx;
	}
	
} //end LdapStuff class
	
Cookie[] cookies = request.getCookies();
  String authTokenString = "";
  for (Cookie cooky : cookies) {
      if (cooky.getName().equals("ZM_AUTH_TOKEN")) {
          authTokenString = cooky.getValue();
      }
  }
AuthToken authToken = AuthToken.getAuthToken(authTokenString);
Account acct = Provisioning.getInstance().get(AccountBy.id, authToken.getAccountId());

String zimbraUid = acct.getUid();
String action = (String) request.getParameter("action");

PrintWriter output = response.getWriter();

String args[] = {zimbraUid, action};
String foo = new LdapStuff().init(args, output);
output.println(foo);

%>
