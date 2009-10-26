<%@ page contentType='text/xml'%>
<%@ page language="java" %>
<%@ page import="com.sun.jndi.ldap.*" %>
<%@ page import="java.lang.String" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.naming.*" %>
<%@ page import="javax.naming.directory.*" %>
<%@ page import="org.apache.commons.lang.StringEscapeUtils" %>
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
		String search_attrs = GetProperties("search_attrs");
		String result = "";
		if (search_attrs.contains(',')){
			String[] attrs = search_attrs.split(',');
			for (String search_attr: attrs){
				result = result.concat("("+search_attr+"="+zimbraUid+")");
			}
			result = GetPasswordExpirationResult("(|"+result+")");
		}
		else {
			result = GetPasswordExpirationResult("("+search_attrs+"="+zimbraUid+")");
		}
		return result;
	}//end init()

	private String GetProperties(String prop){
		Properties props =  new Properties();
		//try retrieve data from file
		try {
			props.load(new FileInputStream("ldap.properties"));
			prop_val = props.getProperty(prop);
			return prop_val;
		}
		catch(IOException e){
			e.printStackTrace();
		}
	}
	
	private String GetPasswordExpirationResult(String filter){
		String value = "";
		String search_base = GetProperties("search_base");
		try {
			DirContext ctx = LdapConn();
	  		SearchControls searchControls = new SearchControls();
	  		searchControls.setSearchScope(SearchControls.SUBTREE_SCOPE);
			String[] attrNames = {"passwordExpirationTime","pwdChangedTime"};
			searchControls.setReturningAttributes(attrNames);
	  		NamingEnumeration results = ctx.search(search_base, filter, searchControls);
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
		String ldap_server = GetProperties("ldap_server");
		String bind_dn = GetProperties("bind_dn");
		String bind_pass = GetProperties("bind_pass");		

		Properties env = new Properties();
		env.put( Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory" );
		env.put("java.naming.ldap.version", "3");
		env.put( Context.PROVIDER_URL, "ldap://"+ ldap_server + "/");
		env.put( Context.SECURITY_AUTHENTICATION, "simple");
		env.put( Context.SECURITY_PRINCIPAL, bind_dn );
		env.put( Context.SECURITY_CREDENTIALS, bind_pass );
	  
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
